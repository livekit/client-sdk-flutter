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

import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_util' as js_util;
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:dart_webrtc/src/rtc_transform_stream.dart';
import 'package:logging/logging.dart';
import 'package:web/web.dart' as web;

import 'e2ee.cryptor.dart';
import 'e2ee.keyhandler.dart';
import 'e2ee.logger.dart';

@JS()
external web.DedicatedWorkerGlobalScope get self;

extension PropsRTCTransformEventHandler on web.DedicatedWorkerGlobalScope {
  set onrtctransform(Function(dynamic) callback) =>
      js_util.setProperty<Function>(this, 'onrtctransform', callback);
}

var participantCryptors = <FrameCryptor>[];
var keyProviders = <String, KeyProvider>{};

FrameCryptor getTrackCryptor(
    String participantIdentity, String trackId, KeyProvider keyProvider) {
  var cryptor =
      participantCryptors.firstWhereOrNull((c) => c.trackId == trackId);
  if (cryptor == null) {
    logger.info(
        'creating new cryptor for $participantIdentity, trackId $trackId');

    cryptor = FrameCryptor(
      worker: self,
      participantIdentity: participantIdentity,
      trackId: trackId,
      keyHandler: keyProvider.getParticipantKeyHandler(participantIdentity),
    );
    //setupCryptorErrorEvents(cryptor);
    participantCryptors.add(cryptor);
  } else if (participantIdentity != cryptor.participantIdentity) {
    // assign new participant id to track cryptor and pass in correct key handler
    cryptor.setParticipant(participantIdentity,
        keyProvider.getParticipantKeyHandler(participantIdentity));
  }
  if (keyProvider.keyProviderOptions.sharedKey) {}
  return cryptor;
}

void unsetCryptorParticipant(String trackId) {
  participantCryptors
      .firstWhereOrNull((c) => c.trackId == trackId)
      ?.unsetParticipant();
}

void main() async {
  // configure logs for debugging
  Logger.root.level = Level.FINE;
  Logger.root.onRecord.listen((record) {
    // ignore: avoid_print
    print('[${record.loggerName}] ${record.level.name}: ${record.message}');
  });

  logger.info('Worker created');

  if (js_util.getProperty(self, 'RTCTransformEvent') != null) {
    logger.info('setup RTCTransformEvent event handler');
    self.onrtctransform = (web.RTCTransformEvent event) {
      logger.info('Got onrtctransform event');
      var transformer = (event as RTCTransformEvent).transformer;

      transformer.handled = true;

      var options = transformer.options;
      var kind = js_util.getProperty(options, 'kind');
      var participantId = js_util.getProperty(options, 'participantId');
      var trackId = js_util.getProperty(options, 'trackId');
      var codec = js_util.getProperty(options, 'codec');
      var msgType = js_util.getProperty(options, 'msgType');
      var keyProviderId = js_util.getProperty(options, 'keyProviderId');

      var keyProvider = keyProviders[keyProviderId];

      if (keyProvider == null) {
        logger.warning('KeyProvider not found for $keyProviderId');
        return;
      }

      var cryptor = getTrackCryptor(participantId, trackId, keyProvider);

      cryptor.setupTransform(
          operation: msgType,
          readable: transformer.readable,
          writable: transformer.writable,
          trackId: trackId,
          kind: kind,
          codec: codec);
    }.toJS;
  }

  self.onmessage = (web.MessageEvent e) {
    (e) async {
      var msg = e.data;
      var msgType = msg['msgType'];
      var msgId = msg['msgId'] as String?;
      logger.fine('Got message $msgType, msgId $msgId');
      switch (msgType) {
        case 'keyProviderInit':
          {
            var options = msg['keyOptions'];
            var keyProviderId = msg['keyProviderId'] as String;
            var keyProviderOptions = KeyOptions(
                sharedKey: options['sharedKey'],
                ratchetSalt: Uint8List.fromList(
                    base64Decode(options['ratchetSalt'] as String)),
                ratchetWindowSize: options['ratchetWindowSize'],
                failureTolerance: options['failureTolerance'] ?? -1,
                uncryptedMagicBytes: options['uncryptedMagicBytes'] != null
                    ? Uint8List.fromList(
                        base64Decode(options['uncryptedMagicBytes'] as String))
                    : null,
                keyRingSze: options['keyRingSize'] ?? KEYRING_SIZE,
                discardFrameWhenCryptorNotReady:
                    options['discardFrameWhenCryptorNotReady'] ?? false);
            logger.config(
                'Init with keyProviderOptions:\n ${keyProviderOptions.toString()}');

            var keyProvider =
                KeyProvider(self, keyProviderId, keyProviderOptions);
            keyProviders[keyProviderId] = keyProvider;

            self.postMessage({
              'type': 'init',
              'msgId': msgId,
              'msgType': 'response',
            }.jsify());
            break;
          }
        case 'keyProviderDispose':
          {
            var keyProviderId = msg['keyProviderId'] as String;
            logger.config('Dispose keyProvider $keyProviderId');
            keyProviders.remove(keyProviderId);
            self.postMessage({
              'type': 'dispose',
              'msgId': msgId,
              'msgType': 'response',
            }.jsify());
          }
          break;
        case 'enable':
          {
            var enabled = msg['enabled'] as bool;
            var trackId = msg['trackId'] as String;

            var cryptors =
                participantCryptors.where((c) => c.trackId == trackId).toList();
            for (var cryptor in cryptors) {
              logger
                  .config('Set enable $enabled for trackId ${cryptor.trackId}');
              cryptor.setEnabled(enabled);
            }
            self.postMessage({
              'type': 'cryptorEnabled',
              'enable': enabled,
              'msgId': msgId,
              'msgType': 'response',
            }.jsify());
          }
          break;
        case 'decode':
        case 'encode':
          {
            var kind = msg['kind'];
            var exist = msg['exist'] as bool;
            var participantId = msg['participantId'] as String;
            var trackId = msg['trackId'];
            var readable = msg['readableStream'] as ReadableStream;
            var writable = msg['writableStream'] as WritableStream;
            var keyProviderId = msg['keyProviderId'] as String;

            logger.config(
                'SetupTransform for kind $kind, trackId $trackId, participantId $participantId, ${readable.runtimeType} ${writable.runtimeType}}');

            var keyProvider = keyProviders[keyProviderId];
            if (keyProvider == null) {
              logger.warning('KeyProvider not found for $keyProviderId');
              self.postMessage({
                'type': 'cryptorSetup',
                'participantId': participantId,
                'trackId': trackId,
                'exist': exist,
                'operation': msgType,
                'error': 'KeyProvider not found',
                'msgId': msgId,
                'msgType': 'response',
              }.jsify());
              return;
            }

            var cryptor = getTrackCryptor(participantId, trackId, keyProvider);

            await cryptor.setupTransform(
              operation: msgType,
              readable: readable,
              writable: writable,
              trackId: trackId,
              kind: kind,
            );

            self.postMessage({
              'type': 'cryptorSetup',
              'participantId': participantId,
              'trackId': trackId,
              'exist': exist,
              'operation': msgType,
              'msgId': msgId,
              'msgType': 'response',
            }.jsify());
            cryptor.lastError = CryptorError.kNew;
          }
          break;
        case 'removeTransform':
          {
            var trackId = msg['trackId'] as String;
            logger.config('Removing trackId $trackId');
            unsetCryptorParticipant(trackId);
            self.postMessage({
              'type': 'cryptorRemoved',
              'trackId': trackId,
              'msgId': msgId,
              'msgType': 'response',
            }.jsify());
          }
          break;
        case 'setKey':
        case 'setSharedKey':
          {
            var key = Uint8List.fromList(base64Decode(msg['key'] as String));
            var keyIndex = msg['keyIndex'] as int;
            var keyProviderId = msg['keyProviderId'] as String;
            var keyProvider = keyProviders[keyProviderId];
            if (keyProvider == null) {
              logger.warning('KeyProvider not found for $keyProviderId');
              self.postMessage({
                'type': 'setKey',
                'error': 'KeyProvider not found',
                'msgId': msgId,
                'msgType': 'response',
              }.jsify());
              return;
            }
            var keyProviderOptions = keyProvider.keyProviderOptions;
            if (keyProviderOptions.sharedKey) {
              logger.config('Set SharedKey keyIndex $keyIndex');
              keyProvider.setSharedKey(key, keyIndex: keyIndex);
            } else {
              var participantId = msg['participantId'] as String;
              logger.config(
                  'Set key for participant $participantId, keyIndex $keyIndex');
              await keyProvider
                  .getParticipantKeyHandler(participantId)
                  .setKey(key, keyIndex: keyIndex);
            }

            self.postMessage({
              'type': 'setKey',
              'participantId': msg['participantId'],
              'sharedKey': keyProviderOptions.sharedKey,
              'keyIndex': keyIndex,
              'msgId': msgId,
              'msgType': 'response',
            }.jsify());
          }
          break;
        case 'ratchetKey':
        case 'ratchetSharedKey':
          {
            var keyIndex = msg['keyIndex'];
            var participantId = msg['participantId'] as String;
            var keyProviderId = msg['keyProviderId'] as String;
            var keyProvider = keyProviders[keyProviderId];
            if (keyProvider == null) {
              logger.warning('KeyProvider not found for $keyProviderId');
              self.postMessage({
                'type': 'setKey',
                'error': 'KeyProvider not found',
                'msgId': msgId,
                'msgType': 'response',
              }.jsify());
              return;
            }
            var keyProviderOptions = keyProvider.keyProviderOptions;
            Uint8List? newKey;
            if (keyProviderOptions.sharedKey) {
              logger.config('RatchetKey for SharedKey, keyIndex $keyIndex');
              newKey =
                  await keyProvider.getSharedKeyHandler().ratchetKey(keyIndex);
            } else {
              logger.config(
                  'RatchetKey for participant $participantId, keyIndex $keyIndex');
              newKey = await keyProvider
                  .getParticipantKeyHandler(participantId)
                  .ratchetKey(keyIndex);
            }

            self.postMessage({
              'type': 'ratchetKey',
              'sharedKey': keyProviderOptions.sharedKey,
              'participantId': participantId,
              'newKey': newKey != null ? base64Encode(newKey) : '',
              'keyIndex': keyIndex,
              'msgId': msgId,
              'msgType': 'response',
            }.jsify());
          }
          break;
        case 'setKeyIndex':
          {
            var keyIndex = msg['index'];
            var trackId = msg['trackId'] as String;
            logger.config('Setup key index for track $trackId');
            var cryptors =
                participantCryptors.where((c) => c.trackId == trackId).toList();
            for (var c in cryptors) {
              logger.config('Set keyIndex for trackId ${c.trackId}');
              c.setKeyIndex(keyIndex);
            }

            self.postMessage({
              'type': 'setKeyIndex',
              'keyIndex': keyIndex,
              'msgId': msgId,
              'msgType': 'response',
            }.jsify());
          }
          break;
        case 'exportKey':
        case 'exportSharedKey':
          {
            var keyIndex = msg['keyIndex'] as int;
            var participantId = msg['participantId'] as String;
            var keyProviderId = msg['keyProviderId'] as String;
            var keyProvider = keyProviders[keyProviderId];
            if (keyProvider == null) {
              logger.warning('KeyProvider not found for $keyProviderId');
              self.postMessage({
                'type': 'setKey',
                'error': 'KeyProvider not found',
                'msgId': msgId,
                'msgType': 'response',
              }.jsify());
              return;
            }
            var keyProviderOptions = keyProvider.keyProviderOptions;
            Uint8List? key;
            if (keyProviderOptions.sharedKey) {
              logger.config('Export SharedKey keyIndex $keyIndex');
              key = await keyProvider.getSharedKeyHandler().exportKey(keyIndex);
            } else {
              logger.config(
                  'Export key for participant $participantId, keyIndex $keyIndex');
              key = await keyProvider
                  .getParticipantKeyHandler(participantId)
                  .exportKey(keyIndex);
            }
            self.postMessage({
              'type': 'exportKey',
              'participantId': participantId,
              'keyIndex': keyIndex,
              'exportedKey': key != null ? base64Encode(key) : '',
              'msgId': msgId,
              'msgType': 'response',
            }.jsify());
          }
          break;
        case 'setSifTrailer':
          {
            var sifTrailer =
                Uint8List.fromList(base64Decode(msg['sifTrailer'] as String));
            var keyProviderId = msg['keyProviderId'] as String;
            var keyProvider = keyProviders[keyProviderId];
            if (keyProvider == null) {
              logger.warning('KeyProvider not found for $keyProviderId');
              self.postMessage({
                'type': 'setKey',
                'error': 'KeyProvider not found',
                'msgId': msgId,
                'msgType': 'response',
              }.jsify());
              return;
            }
            keyProvider.setSifTrailer(sifTrailer);
            logger.config('SetSifTrailer = $sifTrailer');
            for (var c in participantCryptors) {
              c.setSifTrailer(sifTrailer);
            }

            self.postMessage({
              'type': 'setSifTrailer',
              'msgId': msgId,
              'msgType': 'response',
            }.jsify());
          }
          break;
        case 'updateCodec':
          {
            var codec = msg['codec'] as String;
            var trackId = msg['trackId'] as String;
            logger.config('Update codec for trackId $trackId, codec $codec');
            var cryptor = participantCryptors
                .firstWhereOrNull((c) => c.trackId == trackId);
            cryptor?.updateCodec(codec);

            self.postMessage({
              'type': 'updateCodec',
              'msgId': msgId,
              'msgType': 'response',
            }.jsify());
          }
          break;
        case 'dispose':
          {
            var trackId = msg['trackId'] as String;
            logger.config('Dispose for trackId $trackId');
            var cryptor = participantCryptors
                .firstWhereOrNull((c) => c.trackId == trackId);
            if (cryptor != null) {
              cryptor.lastError = CryptorError.kDisposed;
              self.postMessage({
                'type': 'cryptorDispose',
                'participantId': cryptor.participantIdentity,
                'trackId': trackId,
                'msgId': msgId,
                'msgType': 'response',
              }.jsify());
            } else {
              self.postMessage({
                'type': 'cryptorDispose',
                'error': 'cryptor not found',
                'msgId': msgId,
                'msgType': 'response',
              }.jsify());
            }
          }
          break;
        default:
          logger.warning('Unknown message kind $msg');
      }
    }(e);
  }.toJS;
}
