import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:math';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

import 'crypto.dart';
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
    logger.info('setupTransform $operation');
    this.kind = kind;
    if (codec != null) {
      logger.info('setting codec on cryptor to $codec');
      this.codec = codec;
    }
    var transformer = web.TransformStream({
      'transform': operation == 'encode' ? encodeFunction : decodeFunction
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

  int getUnencryptedBytes(web.RTCEncodedVideoFrame frame, String? codec) {
    if (codec != null && codec.toLowerCase() == 'h264') {
      var data = frame.data.toDart.asUint8List();
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
    switch (frame.type) {
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

  Future<void> encodeFunction(
    web.RTCEncodedVideoFrame frame,
    web.TransformStreamDefaultController controller,
  ) async {
    var buffer = frame.data.toDart.asUint8List();

    if (!enabled ||
        // skip for encryption for empty dtx frames
        buffer.isEmpty) {
      if (keyOptions.discardFrameWhenCryptorNotReady) {
        return;
      }
      controller.enqueue(frame);
      return;
    }

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

    try {
      var headerLength =
          kind == 'video' ? getUnencryptedBytes(frame, codec) : 1;
      var metaData = frame.getMetadata();
      var iv = makeIv(
          synchronizationSource: metaData.synchronizationSource,
          timestamp:
              (frame.getProperty('timestamp'.toJS) as JSNumber).toDartInt);

      var frameTrailer = ByteData(2);
      frameTrailer.setInt8(0, IV_LENGTH);
      frameTrailer.setInt8(1, keyIndex);

      var cipherText = Uint8List.view(((await web.window.crypto.subtle
              .encrypt(
                {
                  'name': 'AES-GCM',
                  'iv': iv.toJS,
                  'additionalData': buffer.sublist(0, headerLength).toJS,
                }.jsify() as JSAny,
                secretKey,
                buffer.sublist(headerLength, buffer.length).toJS,
              )
              .toDart) as JSArrayBuffer)
          .toDart);

      logger
          .finer('buffer: ${buffer.length}, cipherText: ${cipherText.length}');
      var finalBuffer = BytesBuilder();

      finalBuffer.add(Uint8List.fromList(buffer.sublist(0, headerLength)));
      finalBuffer.add(cipherText);
      finalBuffer.add(iv);
      finalBuffer.add(frameTrailer.buffer.asUint8List());
      frame.data = finalBuffer.toBytes().buffer.toJS;

      controller.enqueue(frame);

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
          'encrypto kind $kind,codec $codec headerLength: $headerLength,  timestamp: ${frame.getProperty('timestamp'.toJS)}, ssrc: ${metaData.synchronizationSource}, data length: ${buffer.length}, encrypted length: ${finalBuffer.toBytes().length}, iv $iv');
    } catch (e) {
      logger.warning('encrypt: e ${e.toString()}');
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

  Future<void> decodeFunction(
    web.RTCEncodedVideoFrame frame,
    web.TransformStreamDefaultController controller,
  ) async {
    var ratchetCount = 0;
    var buffer = frame.data.toDart;
    ByteBuffer? decrypted;
    KeySet? initialKeySet;
    var initialKeyIndex = currentKeyIndex;

    if (!enabled ||
        // skip for encryption for empty dtx frames
        buffer.lengthInBytes == 0) {
      sifGuard.recordUserFrame();
      if (keyOptions.discardFrameWhenCryptorNotReady) return;
      logger.fine('enqueing empty frame');
      controller.enqueue(frame);
      return;
    }

    if (keyOptions.uncryptedMagicBytes != null) {
      var magicBytes = keyOptions.uncryptedMagicBytes!;
      if (buffer.lengthInBytes > magicBytes.length + 1) {
        var magicBytesBuffer = buffer.asByteData(
            buffer.lengthInBytes - magicBytes.length - 1,
            buffer.lengthInBytes - 1);
        logger.finer(
            'magicBytesBuffer $magicBytesBuffer, magicBytes $magicBytes');
        if (magicBytesBuffer.toString() == magicBytes.toString()) {
          sifGuard.recordSif();
          if (sifGuard.isSifAllowed()) {
            var frameType =
                buffer.asByteData(buffer.lengthInBytes - 1).getInt8(0);
            logger.finer('skip uncrypted frame, type $frameType');

            final view = buffer.asByteData(
                0, buffer.lengthInBytes - (magicBytes.length + 1));
            frame.data = jsArrayBufferFrom(view);
            logger.fine('enqueing silent frame');
            controller.enqueue(frame);
          } else {
            logger.finer('SIF limit reached, dropping frame');
          }
          return;
        } else {
          sifGuard.recordUserFrame();
        }
      }
    }

    try {
      var headerLength =
          kind == 'video' ? getUnencryptedBytes(frame, codec) : 1;
      var metaData = frame.getMetadata();

      var frameTrailer = buffer.asByteData(buffer.lengthInBytes - 2);
      var ivLength = frameTrailer.getInt8(0);
      var keyIndex = frameTrailer.getInt8(1);
      var iv = buffer.asByteData(
          buffer.lengthInBytes - ivLength - 2, buffer.lengthInBytes - 2);

      initialKeySet = keyHandler.getKeySet(keyIndex);
      initialKeyIndex = keyIndex;

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
        decrypted = ((await web.window.crypto.subtle
                .decrypt(
                  {
                    'name': 'AES-GCM',
                    'iv': jsArrayBufferFrom(iv),
                    'additionalData':
                        jsArrayBufferFrom(buffer.asByteData(0, headerLength)),
                  }.jsify() as JSAny,
                  currentkeySet.encryptionKey,
                  jsArrayBufferFrom(buffer.asByteData(
                      headerLength, buffer.lengthInBytes - ivLength - 2)),
                )
                .toDart) as JSArrayBuffer)
            .toDart;
        if (decrypted == null) {
          throw Exception('[decryptFrameInternal] could not decrypt');
        }

        if (currentkeySet != initialKeySet) {
          logger.fine('ratchetKey: decryption ok, newState: kKeyRatcheted');
          await keyHandler.setKeySetFromMaterial(
              currentkeySet, initialKeyIndex);
        }

        if (lastError != CryptorError.kOk &&
            lastError != CryptorError.kKeyRatcheted &&
            ratchetCount > 0) {
          logger.finer(
              'KeyRatcheted: ssrc ${metaData.synchronizationSource} timestamp ${frame.getProperty('timestamp'.toJS)} ratchetCount $ratchetCount  participantId: $participantIdentity');
          logger.finer(
              'ratchetKey: lastError != CryptorError.kKeyRatcheted, reset state to kKeyRatcheted');

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
        await ratchedKeyInternal();
      }

      if (decrypted == null) {
        throw Exception(
            '[decodeFunction] decryption failed even after ratchting');
      }

      // we can now be sure that decryption was a success
      keyHandler.decryptionSuccess();

      logger.finer(
          'buffer: ${buffer.lengthInBytes}, decrypted: ${decrypted!.asUint8List().length}');

      var finalBuffer = BytesBuilder();

      finalBuffer
          .add(Uint8List.sublistView(buffer.asByteData(0, headerLength)));
      finalBuffer.add(decrypted!.asUint8List());
      frame.data = finalBuffer.toBytes().buffer.toJS;
      controller.enqueue(frame);

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
          'decrypto kind $kind,codec $codec headerLength: $headerLength, timestamp: ${frame.getProperty("timestamp".toJS)}, ssrc: ${metaData.synchronizationSource}, data length: ${buffer.lengthInBytes}, decrypted length: ${finalBuffer.toBytes().length}, keyindex $keyIndex iv $iv');
    } catch (e) {
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
