import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:math';
import 'dart:typed_data';

import 'package:web/web.dart' as web;
import 'e2ee.keyhandler.dart';
import 'e2ee.logger.dart';
import 'e2ee.sfi_guard.dart';

const IV_LENGTH = 12;

const kNaluTypeMask = 0x1f;

/// Coded slice of a non-IDR picture
const SLICE_NON_IDR = 1;

/// Coded slice data partition A
const SLICE_PARTITION_A = 2;

/// Coded slice data partition B
const SLICE_PARTITION_B = 3;

/// Coded slice data partition C
const SLICE_PARTITION_C = 4;

/// Coded slice of an IDR picture
const SLICE_IDR = 5;

/// Supplemental enhancement information
const SEI = 6;

/// Sequence parameter set
const SPS = 7;

/// Picture parameter set
const PPS = 8;

/// Access unit delimiter
const AUD = 9;

/// End of sequence
const END_SEQ = 10;

/// End of stream
const END_STREAM = 11;

/// Filler data
const FILLER_DATA = 12;

/// Sequence parameter set extension
const SPS_EXT = 13;

/// Prefix NAL unit
const PREFIX_NALU = 14;

/// Subset sequence parameter set
const SUBSET_SPS = 15;

/// Depth parameter set
const DPS = 16;

// 17, 18 reserved

/// Coded slice of an auxiliary coded picture without partitioning
const SLICE_AUX = 19;

/// Coded slice extension
const SLICE_EXT = 20;

/// Coded slice extension for a depth view component or a 3D-AVC texture view component
const SLICE_LAYER_EXT = 21;

// 22, 23 reserved

List<int> findNALUIndices(Uint8List stream) {
  var result = <int>[];
  var start = 0, pos = 0, searchLength = stream.length - 2;
  while (pos < searchLength) {
    // skip until end of current NALU
    while (pos < searchLength &&
        !(stream[pos] == 0 && stream[pos + 1] == 0 && stream[pos + 2] == 1)) {
      pos++;
    }
    if (pos >= searchLength) pos = stream.length;
    // remove trailing zeros from current NALU
    var end = pos;
    while (end > start && stream[end - 1] == 0) {
      end--;
    }
    // save current NALU
    if (start == 0) {
      if (end != start) throw Exception('byte stream contains leading data');
    } else {
      result.add(start);
    }
    // begin new NALU
    start = pos = pos + 3;
  }
  return result;
}

int parseNALUType(int startByte) {
  return startByte & kNaluTypeMask;
}

enum CryptorError {
  kNew,
  kOk,
  kDecryptError,
  kEncryptError,
  kUnsupportedCodec,
  kMissingKey,
  kKeyRatcheted,
  kInternalError,
  kDisposed,
}

class FrameInfo {
  FrameInfo({
    required this.ssrc,
    required this.timestamp,
    required this.buffer,
    required this.frameType,
  });
  String frameType;
  int ssrc;
  int timestamp;
  Uint8List buffer;
}

class FrameCryptor {
  FrameCryptor({
    required this.worker,
    required this.participantIdentity,
    required this.trackId,
    required this.keyHandler,
  });
  Map<int, int> sendCounts = {};
  String? participantIdentity;
  String? trackId;
  String? codec;
  ParticipantKeyHandler keyHandler;
  KeyOptions get keyOptions => keyHandler.keyOptions;
  late String kind;
  bool _enabled = false;
  CryptorError lastError = CryptorError.kNew;
  int currentKeyIndex = 0;
  final web.DedicatedWorkerGlobalScope worker;
  SifGuard sifGuard = SifGuard();

  void setParticipant(String identity, ParticipantKeyHandler keys) {
    if (lastError != CryptorError.kOk) {
      logger.info(
          'setParticipantId: lastError != CryptorError.kOk, reset state to kNew');
      lastError = CryptorError.kNew;
    }
    participantIdentity = identity;
    keyHandler = keys;
    sifGuard.reset();
  }

  void unsetParticipant() {
    participantIdentity = null;
  }

  void setKeyIndex(int keyIndex) {
    if (lastError != CryptorError.kOk) {
      logger.info(
          'setKeyIndex: lastError != CryptorError.kOk, reset state to kNew');
      lastError = CryptorError.kNew;
    }
    logger.config('setKeyIndex for $participantIdentity, newIndex: $keyIndex');
    currentKeyIndex = keyIndex;
  }

  void setSifTrailer(Uint8List? magicBytes) {
    logger.config(
        'setSifTrailer for $participantIdentity, magicBytes: $magicBytes');
    keyOptions.uncryptedMagicBytes = magicBytes;
  }

  void setEnabled(bool enabled) {
    if (lastError != CryptorError.kOk) {
      logger.info(
          'setEnabled[$enabled]: lastError != CryptorError.kOk, reset state to kNew');
      lastError = CryptorError.kNew;
    }
    logger.config('setEnabled for $participantIdentity, enabled: $enabled');
    _enabled = enabled;
  }

  bool get enabled {
    if (participantIdentity == null) {
      return false;
    }
    return _enabled;
  }

  void updateCodec(String codec) {
    if (lastError != CryptorError.kOk) {
      logger.info(
          'updateCodec[$codec]: lastError != CryptorError.kOk, reset state to kNew');
      lastError = CryptorError.kNew;
    }
    logger.config('updateCodec for $participantIdentity, codec: $codec');
    this.codec = codec;
  }

  Uint8List makeIv(
      {required int synchronizationSource, required int timestamp}) {
    var iv = ByteData(IV_LENGTH);

    // having to keep our own send count (similar to a picture id) is not ideal.
    if (sendCounts[synchronizationSource] == null) {
      // Initialize with a random offset, similar to the RTP sequence number.
      sendCounts[synchronizationSource] = Random.secure().nextInt(0xffff);
    }

    var sendCount = sendCounts[synchronizationSource] ?? 0;

    iv.setUint32(0, synchronizationSource);
    iv.setUint32(4, timestamp);
    iv.setUint32(8, timestamp - (sendCount % 0xffff));

    sendCounts[synchronizationSource] = sendCount + 1;

    return iv.buffer.asUint8List();
  }

  void postMessage(Object message) {
    worker.postMessage(message.jsify());
  }

  Future<void> setupTransform({
    required String operation,
    required web.ReadableStream readable,
    required web.WritableStream writable,
    required String trackId,
    required String kind,
    String? codec,
  }) async {
    logger.info('setupTransform $operation kind $kind');
    this.kind = kind;
    if (codec != null) {
      logger.info('setting codec on cryptor to $codec');
      this.codec = codec;
    }
    var transformer = web.TransformStream({
      'transform':
          (operation == 'encode' ? encodeFunction.toJS : decodeFunction.toJS)
    }.jsify() as JSObject);
    try {
      readable
          .pipeThrough(transformer as web.ReadableWritablePair)
          .pipeTo(writable);
    } catch (e) {
      logger.warning('e ${e.toString()}');
      if (lastError != CryptorError.kInternalError) {
        lastError = CryptorError.kInternalError;
        postMessage({
          'type': 'cryptorState',
          'msgType': 'event',
          'participantId': participantIdentity,
          'state': 'internalError',
          'error': 'Internal error: ${e.toString()}'
        });
      }
    }
    this.trackId = trackId;
  }

  int getUnencryptedBytes(JSObject obj, String? codec) {
    Uint8List data = Uint8List(0);
    var frameType = '';
    if (obj is web.RTCEncodedVideoFrame) {
      data = obj.data.toDart.asUint8List();
      if (obj.hasProperty('type'.toJS).toDart) {
        frameType = obj.type;
        logger.finer('frameType: $frameType');
      }
    }

    if (codec != null && codec.toLowerCase() == 'h264') {
      var naluIndices = findNALUIndices(data);
      for (var index in naluIndices) {
        var type = parseNALUType(data[index]);
        switch (type) {
          case SLICE_IDR:
          case SLICE_NON_IDR:
            // skipping
            logger.finer(
                'unEncryptedBytes NALU of type $type, offset ${index + 2}');
            return index + 2;
          default:
            logger.finer('skipping NALU of type $type');
            break;
        }
      }
      throw Exception('Could not find NALU');
    }
    switch (frameType) {
      case 'key':
        return 10;
      case 'delta':
        return 3;
      case 'audio':
        return 1; // frame.type is not set on audio, so this is set manually
      default:
        return 0;
    }
  }

  FrameInfo readFrameInfo(JSObject frameObj) {
    var buffer = Uint8List(0);
    var synchronizationSource = 0;
    var timestamp = 0;
    var frameType = '';
    if (frameObj is web.RTCEncodedVideoFrame) {
      buffer = frameObj.data.toDart.asUint8List();
      if (frameObj.hasProperty('type'.toJS).toDart) {
        frameType = frameObj.type;
        logger.finer('frameType: $frameType');
      }
      synchronizationSource = frameObj.getMetadata().synchronizationSource;
      if (frameObj.getMetadata().hasProperty('rtpTimestamp'.toJS).toDart) {
        timestamp = frameObj.getMetadata().rtpTimestamp.toInt();
      } else if (frameObj.hasProperty('timestamp'.toJS).toDart) {
        timestamp =
            (frameObj.getProperty('timestamp'.toJS) as JSNumber).toDartInt;
      }
    } else if (frameObj is web.RTCEncodedAudioFrame) {
      buffer = frameObj.data.toDart.asUint8List();
      synchronizationSource = frameObj.getMetadata().synchronizationSource;

      if (frameObj.getMetadata().hasProperty('rtpTimestamp'.toJS).toDart) {
        timestamp = frameObj.getMetadata().rtpTimestamp.toInt();
      } else if (frameObj.hasProperty('timestamp'.toJS).toDart) {
        timestamp =
            (frameObj.getProperty('timestamp'.toJS) as JSNumber).toDartInt;
      }
      frameType = 'audio';
    } else {
      throw Exception(
          'encodeFunction: frame is not a RTCEncodedVideoFrame or RTCEncodedAudioFrame');
    }

    return FrameInfo(
      ssrc: synchronizationSource,
      timestamp: timestamp,
      buffer: buffer,
      frameType: frameType,
    );
  }

  void enqueueFrame(JSObject frameObj,
      web.TransformStreamDefaultController controller, BytesBuilder buffer) {
    if (frameObj is web.RTCEncodedVideoFrame) {
      frameObj.data = buffer.toBytes().buffer.toJS;
    } else if (frameObj is web.RTCEncodedAudioFrame) {
      frameObj.data = buffer.toBytes().buffer.toJS;
    }
    controller.enqueue(frameObj);
  }

  void encodeFunction(
    JSObject frameObj,
    web.TransformStreamDefaultController controller,
  ) async {
    try {
      if (!enabled ||
          // skip for encryption for empty dtx frames
          ((frameObj is web.RTCEncodedVideoFrame &&
                  frameObj.data.toDart.lengthInBytes == 0) ||
              (frameObj is web.RTCEncodedAudioFrame &&
                  frameObj.data.toDart.lengthInBytes == 0))) {
        if (keyOptions.discardFrameWhenCryptorNotReady) {
          return;
        }
        controller.enqueue(frameObj);
        return;
      }

      var srcFrame = readFrameInfo(frameObj);

      logger.finer(
          'encodeFunction: buffer ${srcFrame.buffer.length}, synchronizationSource ${srcFrame.ssrc} frameType ${srcFrame.frameType}');

      var secretKey = keyHandler.getKeySet(currentKeyIndex)?.encryptionKey;
      var keyIndex = currentKeyIndex;

      if (secretKey == null) {
        if (lastError != CryptorError.kMissingKey) {
          lastError = CryptorError.kMissingKey;
          postMessage({
            'type': 'cryptorState',
            'msgType': 'event',
            'participantId': participantIdentity,
            'trackId': trackId,
            'kind': kind,
            'state': 'missingKey',
            'error': 'Missing key for track $trackId',
          });
        }
        return;
      }

      var headerLength =
          kind == 'video' ? getUnencryptedBytes(frameObj, codec) : 1;

      var iv = makeIv(
          synchronizationSource: srcFrame.ssrc, timestamp: srcFrame.timestamp);

      var frameTrailer = ByteData(2);
      frameTrailer.setInt8(0, IV_LENGTH);
      frameTrailer.setInt8(1, keyIndex);

      var cipherText = await worker.crypto.subtle
          .encrypt(
            {
              'name': 'AES-GCM',
              'iv': iv,
              'additionalData': srcFrame.buffer.sublist(0, headerLength),
            }.jsify() as web.AlgorithmIdentifier,
            secretKey,
            srcFrame.buffer.sublist(headerLength, srcFrame.buffer.length).toJS,
          )
          .toDart as JSArrayBuffer;

      logger.finer(
          'encodeFunction: encrypted buffer: ${srcFrame.buffer.length}, cipherText: ${cipherText.toDart.asUint8List().length}');
      var finalBuffer = BytesBuilder();

      finalBuffer
          .add(Uint8List.fromList(srcFrame.buffer.sublist(0, headerLength)));
      finalBuffer.add(cipherText.toDart.asUint8List());
      finalBuffer.add(iv);
      finalBuffer.add(frameTrailer.buffer.asUint8List());

      enqueueFrame(frameObj, controller, finalBuffer);

      if (lastError != CryptorError.kOk) {
        lastError = CryptorError.kOk;
        postMessage({
          'type': 'cryptorState',
          'msgType': 'event',
          'participantId': participantIdentity,
          'trackId': trackId,
          'kind': kind,
          'state': 'ok',
          'error': 'encryption ok'
        });
      }

      logger.finer(
          'encodeFunction[CryptorError.kOk]: frame enqueued kind $kind,codec $codec headerLength: $headerLength,  timestamp: ${srcFrame.timestamp}, ssrc: ${srcFrame.ssrc}, data length: ${srcFrame.buffer.length}, encrypted length: ${finalBuffer.toBytes().length}, iv $iv');
    } catch (e) {
      logger.warning('encodeFunction encrypt: e ${e.toString()}');
      if (lastError != CryptorError.kEncryptError) {
        lastError = CryptorError.kEncryptError;
        postMessage({
          'type': 'cryptorState',
          'msgType': 'event',
          'participantId': participantIdentity,
          'trackId': trackId,
          'kind': kind,
          'state': 'encryptError',
          'error': e.toString()
        });
      }
    }
  }

  void decodeFunction(
    JSObject frameObj,
    web.TransformStreamDefaultController controller,
  ) async {
    var srcFrame = readFrameInfo(frameObj);
    var ratchetCount = 0;

    logger.finer('decodeFunction: frame length ${srcFrame.buffer.length}');

    ByteBuffer? decrypted;
    KeySet? initialKeySet;
    var initialKeyIndex = currentKeyIndex;

    if (!enabled ||
        // skip for encryption for empty dtx frames
        srcFrame.buffer.isEmpty) {
      sifGuard.recordUserFrame();
      if (keyOptions.discardFrameWhenCryptorNotReady) return;
      logger.fine('enqueing empty dtx frame');
      controller.enqueue(frameObj);
      return;
    }

    if (keyOptions.uncryptedMagicBytes != null) {
      var magicBytes = keyOptions.uncryptedMagicBytes!;
      if (srcFrame.buffer.length > magicBytes.length + 1) {
        var magicBytesBuffer = srcFrame.buffer.sublist(
            srcFrame.buffer.length - magicBytes.length, srcFrame.buffer.length);
        logger.finer(
            'magicBytesBuffer $magicBytesBuffer, magicBytes $magicBytes');
        if (magicBytesBuffer.toString() == magicBytes.toString()) {
          sifGuard.recordSif();
          if (sifGuard.isSifAllowed()) {
            var frameType =
                srcFrame.buffer.sublist(srcFrame.buffer.length - 1)[0];
            logger.finer(
                'encodeFunction: skip unencrypted frame, type $frameType');
            var finalBuffer = BytesBuilder();
            finalBuffer.add(Uint8List.fromList(srcFrame.buffer
                .sublist(0, srcFrame.buffer.length - (magicBytes.length + 1))));
            logger.fine(
                'encodeFunction: enqueing silent frame');
            enqueueFrame(frameObj, controller, finalBuffer);
            return;
          } else {
            logger.fine('encodeFunction: SIF limit reached, dropping frame');
            return;
          }
        } else {
          sifGuard.recordUserFrame();
        }
      }
    }

    try {
      var headerLength =
          kind == 'video' ? getUnencryptedBytes(frameObj, codec) : 1;

      var frameTrailer = srcFrame.buffer.sublist(srcFrame.buffer.length - 2);
      var ivLength = frameTrailer[0];
      var keyIndex = frameTrailer[1];
      var iv = srcFrame.buffer.sublist(
          srcFrame.buffer.length - ivLength - 2, srcFrame.buffer.length - 2);

      initialKeySet = keyHandler.getKeySet(keyIndex);
      initialKeyIndex = keyIndex;

      logger.finer(
          'decodeFunction: start decrypting frame headerLength $headerLength ${srcFrame.buffer.length} frameTrailer $frameTrailer, ivLength $ivLength, keyIndex $keyIndex, iv $iv');

      /// missingKey flow:
      /// tries to decrypt once, fails, tries to ratchet once and decrypt again,
      /// fails (does not save ratcheted key), bumps _decryptionFailureCount,
      /// if higher than failuretolerance hasValidKey is set to false, on next
      /// frame it fires a missingkey
      /// to throw missingkeys faster lower your failureTolerance
      if (initialKeySet == null || !keyHandler.hasValidKey) {
        if (lastError != CryptorError.kMissingKey) {
          lastError = CryptorError.kMissingKey;
          postMessage({
            'type': 'cryptorState',
            'msgType': 'event',
            'participantId': participantIdentity,
            'trackId': trackId,
            'kind': kind,
            'state': 'missingKey',
            'error': 'Missing key for track $trackId'
          });
        }
        // controller.enqueue(frame);
        return;
      }
      var currentkeySet = initialKeySet;

      Future<void> decryptFrameInternal() async {
        decrypted = ((await worker.crypto.subtle
                .decrypt(
                  {
                    'name': 'AES-GCM',
                    'iv': iv,
                    'additionalData': srcFrame.buffer.sublist(0, headerLength),
                  }.jsify() as web.AlgorithmIdentifier,
                  currentkeySet.encryptionKey,
                  srcFrame.buffer
                      .sublist(
                          headerLength, srcFrame.buffer.length - ivLength - 2)
                      .toJS,
                )
                .toDart) as JSArrayBuffer)
            .toDart;
        logger.finer(
            'decodeFunction::decryptFrameInternal: decrypted: ${decrypted!.asUint8List().length}');

        if (decrypted == null) {
          throw Exception('[decryptFrameInternal] could not decrypt');
        }
        logger.finer(
            'decodeFunction::decryptFrameInternal: decrypted: ${decrypted!.asUint8List().length}');
        if (currentkeySet != initialKeySet) {
          logger.fine(
              'decodeFunction::decryptFrameInternal: ratchetKey: decryption ok, newState: kKeyRatcheted');
          await keyHandler.setKeySetFromMaterial(
              currentkeySet, initialKeyIndex);
        }

        if (lastError != CryptorError.kOk &&
            lastError != CryptorError.kKeyRatcheted &&
            ratchetCount > 0) {
          logger.finer(
              'decodeFunction::decryptFrameInternal: KeyRatcheted: ssrc ${srcFrame.ssrc} timestamp ${srcFrame.timestamp} ratchetCount $ratchetCount  participantId: $participantIdentity');
          logger.finer(
              'decodeFunction::decryptFrameInternal: ratchetKey: lastError != CryptorError.kKeyRatcheted, reset state to kKeyRatcheted');

          lastError = CryptorError.kKeyRatcheted;
          postMessage({
            'type': 'cryptorState',
            'msgType': 'event',
            'participantId': participantIdentity,
            'trackId': trackId,
            'kind': kind,
            'state': 'keyRatcheted',
            'error': 'Key ratcheted ok'
          });
        }
      }

      Future<void> ratchedKeyInternal() async {
        if (ratchetCount >= keyOptions.ratchetWindowSize ||
            keyOptions.ratchetWindowSize <= 0) {
          throw Exception('[ratchedKeyInternal] cannot ratchet anymore');
        }

        var newKeyBuffer = await keyHandler.ratchet(
            currentkeySet.material, keyOptions.ratchetSalt);
        var newMaterial = await keyHandler.ratchetMaterial(
            currentkeySet.material, newKeyBuffer.buffer);
        currentkeySet =
            await keyHandler.deriveKeys(newMaterial, keyOptions.ratchetSalt);
        ratchetCount++;
        await decryptFrameInternal();
      }

      try {
        /// gets frame -> tries to decrypt -> tries to ratchet (does this failureTolerance
        /// times, then says missing key)
        /// we only save the new key after ratcheting if we were able to decrypt something
        await decryptFrameInternal();
      } catch (e) {
        lastError = CryptorError.kInternalError;
        logger.finer('decodeFunction: kInternalError catch $e');
        await ratchedKeyInternal();
      }

      if (decrypted == null) {
        throw Exception(
            '[decodeFunction] decryption failed even after ratchting');
      }

      // we can now be sure that decryption was a success
      keyHandler.decryptionSuccess();

      logger.finer(
          'decodeFunction: decryption success, buffer length ${srcFrame.buffer.length}, decrypted: ${decrypted!.asUint8List().length}');

      var finalBuffer = BytesBuilder();

      finalBuffer
          .add(Uint8List.fromList(srcFrame.buffer.sublist(0, headerLength)));
      finalBuffer.add(decrypted!.asUint8List());
      enqueueFrame(frameObj, controller, finalBuffer);

      if (lastError != CryptorError.kOk) {
        lastError = CryptorError.kOk;
        postMessage({
          'type': 'cryptorState',
          'msgType': 'event',
          'participantId': participantIdentity,
          'trackId': trackId,
          'kind': kind,
          'state': 'ok',
          'error': 'decryption ok'
        });
      }

      logger.finer(
          'decodeFunction[CryptorError.kOk]: decryption success kind $kind, headerLength: $headerLength, timestamp: ${srcFrame.timestamp}, ssrc: ${srcFrame.ssrc}, data length: ${srcFrame.buffer.length}, decrypted length: ${finalBuffer.toBytes().length}, keyindex $keyIndex iv $iv');
    } catch (e, s) {
      logger.info('decodeFunction[CryptorError.kDecryptError]: $e, $s');

      if (lastError != CryptorError.kDecryptError) {
        lastError = CryptorError.kDecryptError;
        postMessage({
          'type': 'cryptorState',
          'msgType': 'event',
          'participantId': participantIdentity,
          'trackId': trackId,
          'kind': kind,
          'state': 'decryptError',
          'error': e.toString()
        });
      }

      keyHandler.decryptionFailure();
    }
  }
}
