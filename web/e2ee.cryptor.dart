// Copyright 2024 LiveKit, Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

// ignore_for_file: constant_identifier_names

import 'dart:async';
import 'dart:html';
import 'dart:js';
import 'dart:js_util' as jsutil;
import 'dart:math';
import 'dart:typed_data';

import 'package:dart_webrtc/src/rtc_transform_stream.dart';
import 'crypto.dart' as crypto;
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
  final DedicatedWorkerGlobalScope worker;
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
    worker.postMessage(message);
  }

  Future<void> setupTransform({
    required String operation,
    required ReadableStream readable,
    required WritableStream writable,
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
    var transformer = TransformStream(jsutil.jsify({
      'transform':
          allowInterop(operation == 'encode' ? encodeFunction : decodeFunction)
    }));
    try {
      readable.pipeThrough(transformer).pipeTo(writable);
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

  int getUnencryptedBytes(RTCEncodedFrame frame, String? codec) {
    if (codec != null && codec.toLowerCase() == 'h264') {
      var data = frame.data.asUint8List();
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
    RTCEncodedFrame frame,
    TransformStreamDefaultController controller,
  ) async {
    var buffer = frame.data.asUint8List();

    if (!enabled ||
        // skip for encryption for empty dtx frames
        buffer.isEmpty) {
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
          'currentKeyIndex': currentKeyIndex,
          'secretKey': secretKey.toString()
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
          timestamp: frame.timestamp);

      var frameTrailer = ByteData(2);
      frameTrailer.setInt8(0, IV_LENGTH);
      frameTrailer.setInt8(1, keyIndex);

      var cipherText = await jsutil.promiseToFuture<ByteBuffer>(crypto.encrypt(
        crypto.AesGcmParams(
          name: 'AES-GCM',
          iv: crypto.jsArrayBufferFrom(iv),
          additionalData:
              crypto.jsArrayBufferFrom(buffer.sublist(0, headerLength)),
        ),
        secretKey,
        crypto.jsArrayBufferFrom(buffer.sublist(headerLength, buffer.length)),
      ));

      logger.finer(
          'buffer: ${buffer.length}, cipherText: ${cipherText.asUint8List().length}');
      var finalBuffer = BytesBuilder();

      finalBuffer.add(Uint8List.fromList(buffer.sublist(0, headerLength)));
      finalBuffer.add(cipherText.asUint8List());
      finalBuffer.add(iv);
      finalBuffer.add(frameTrailer.buffer.asUint8List());
      frame.data = crypto.jsArrayBufferFrom(finalBuffer.toBytes());

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
          'error': 'encryption ok',
          'frameTrailer': frameTrailer.buffer.asUint8List(),
          'currentKeyIndex': currentKeyIndex,
          'secretKey': secretKey.toString(),
        });
      }

      logger.finer(
          'encrypto kind $kind,codec $codec headerLength: $headerLength,  timestamp: ${frame.timestamp}, ssrc: ${metaData.synchronizationSource}, data length: ${buffer.length}, encrypted length: ${finalBuffer.toBytes().length}, iv $iv');
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
    RTCEncodedFrame frame,
    TransformStreamDefaultController controller,
  ) async {
    var ratchetCount = 0;
    var buffer = frame.data.asUint8List();
    ByteBuffer? decrypted;
    KeySet? initialKeySet;
    var initialKeyIndex = currentKeyIndex;

    if (!enabled ||
        // skip for encryption for empty dtx frames
        buffer.isEmpty) {
      sifGuard.recordUserFrame();
      controller.enqueue(frame);
      return;
    }

    if (keyOptions.uncryptedMagicBytes != null) {
      var magicBytes = keyOptions.uncryptedMagicBytes!;
      if (buffer.length > magicBytes.length + 1) {
        var magicBytesBuffer = buffer.sublist(
            buffer.length - magicBytes.length - 1, buffer.length - 1);
        logger.finer(
            'magicBytesBuffer $magicBytesBuffer, magicBytes $magicBytes, ');
        if (magicBytesBuffer.toString() == magicBytes.toString()) {
          sifGuard.recordSif();
          if (sifGuard.isSifAllowed()) {
            var frameType = buffer.sublist(buffer.length - 1)[0];
            logger.finer('skip uncrypted frame, type $frameType');
            var finalBuffer = BytesBuilder();
            finalBuffer.add(Uint8List.fromList(
                buffer.sublist(0, buffer.length - (magicBytes.length + 1))));
            frame.data = crypto.jsArrayBufferFrom(finalBuffer.toBytes());
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

      var frameTrailer = buffer.sublist(buffer.length - 2);
      var ivLength = frameTrailer[0];
      var keyIndex = frameTrailer[1];
      var iv = buffer.sublist(buffer.length - ivLength - 2, buffer.length - 2);

      initialKeySet = keyHandler.getKeySet(keyIndex);
      initialKeyIndex = keyIndex;

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
            'error': 'Missing key for track $trackId',
            'frameTrailer': frameTrailer.buffer.asUint8List(),
            'currentKeyIndex': keyIndex,
            'secretKey': initialKeySet?.encryptionKey.toString()
          });
        }
        controller.enqueue(frame);
        return;
      }
      var endDecLoop = false;
      var currentkeySet = initialKeySet;
      while (!endDecLoop) {
        try {
          decrypted = await jsutil.promiseToFuture<ByteBuffer>(crypto.decrypt(
            crypto.AesGcmParams(
              name: 'AES-GCM',
              iv: crypto.jsArrayBufferFrom(iv),
              additionalData:
                  crypto.jsArrayBufferFrom(buffer.sublist(0, headerLength)),
            ),
            currentkeySet.encryptionKey,
            crypto.jsArrayBufferFrom(
                buffer.sublist(headerLength, buffer.length - ivLength - 2)),
          ));

          if (currentkeySet != initialKeySet) {
            logger.warning(
                'ratchetKey: decryption ok, reset state to kKeyRatcheted');
            await keyHandler.setKeySetFromMaterial(
                currentkeySet, initialKeyIndex);
          }

          endDecLoop = true;

          if (lastError != CryptorError.kOk &&
              lastError != CryptorError.kKeyRatcheted &&
              ratchetCount > 0) {
            logger.finer(
                'KeyRatcheted: ssrc ${metaData.synchronizationSource} timestamp ${frame.timestamp} ratchetCount $ratchetCount  participantId: $participantIdentity');
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
              'error': 'Key ratcheted ok',
              'frameTrailer': frameTrailer.buffer.asUint8List(),
              'currentKeyIndex': currentKeyIndex,
              'secretKey': currentkeySet.encryptionKey.toString()
            });
          }
        } catch (e) {
          lastError = CryptorError.kInternalError;
          endDecLoop = ratchetCount >= keyOptions.ratchetWindowSize ||
              keyOptions.ratchetWindowSize <= 0;
          if (endDecLoop) {
            rethrow;
          }
          var newKeyBuffer = crypto.jsArrayBufferFrom(await keyHandler.ratchet(
              currentkeySet.material, keyOptions.ratchetSalt));
          var newMaterial = await keyHandler.ratchetMaterial(
              currentkeySet.material, newKeyBuffer);
          currentkeySet =
              await keyHandler.deriveKeys(newMaterial, keyOptions.ratchetSalt);
          ratchetCount++;
        }
      }

      logger.finer(
          'buffer: ${buffer.length}, decrypted: ${decrypted?.asUint8List().length ?? 0}');
      var finalBuffer = BytesBuilder();
      finalBuffer.add(Uint8List.fromList(buffer.sublist(0, headerLength)));
      finalBuffer.add(decrypted!.asUint8List());
      frame.data = crypto.jsArrayBufferFrom(finalBuffer.toBytes());
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
          'error': 'decryption ok',
          'frameTrailer': frameTrailer.buffer.asUint8List(),
          'currentKeyIndex': currentKeyIndex,
          'secretKey': currentkeySet.encryptionKey.toString()
        });
      }

      logger.finer(
          'decrypto kind $kind,codec $codec headerLength: $headerLength, timestamp: ${frame.timestamp}, ssrc: ${metaData.synchronizationSource}, data length: ${buffer.length}, decrypted length: ${finalBuffer.toBytes().length}, keyindex $keyIndex iv $iv');
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

      /// Since the key it is first send and only afterwards actually used for encrypting, there were
      /// situations when the decrypting failed due to the fact that the received frame was not encrypted
      /// yet and ratcheting, of course, did not solve the problem. So if we fail RATCHET_WINDOW_SIZE times,
      ///  we come back to the initial key.
      if (initialKeySet != null) {
        logger.warning(
            'decryption failed, ratcheting back to initial key, keyIndex: $initialKeyIndex');
        await keyHandler.setKeySetFromMaterial(initialKeySet, initialKeyIndex);
      }
      keyHandler.decryptionFailure();
    }
  }
}
