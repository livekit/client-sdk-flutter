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
import 'dart:html' as html;
import 'dart:js_util' as js_util;
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:js/js.dart';
import 'package:logging/logging.dart';

import 'package:dart_webrtc/src/rtc_transform_stream.dart';
import 'e2ee.cryptor.dart';
import 'e2ee.keyhandler.dart';
import 'e2ee.logger.dart';

@JS()
abstract class TransformMessage {
  external String get msgType;
  external String get kind;
}

@anonymous
@JS()
class EnableTransformMessage {
  external factory EnableTransformMessage({
    ReadableStream readable,
    WritableStream writable,
    String msgType,
    String kind,
    String participantId,
    String trackId,
    String codec,
  });
  external ReadableStream get readable;
  external WritableStream get writable;
  external String get msgType; // 'encode' or 'decode'
  external String get participantId;
  external String get trackId;
  external String get kind;
  external String get codec;
}

@anonymous
@JS()
class RemoveTransformMessage {
  external factory RemoveTransformMessage(
      {String msgType, String participantId, String trackId});
  external String get msgType; // 'removeTransform'
  external String get participantId;
  external String get trackId;
}

@JS('self')
external html.DedicatedWorkerGlobalScope get self;

extension PropsRTCTransformEventHandler on html.DedicatedWorkerGlobalScope {
  set onrtctransform(Function(dynamic) callback) =>
      js_util.setProperty<Function>(this, 'onrtctransform', callback);
}

var participantCryptors = <FrameCryptor>[];
var participantKeys = <String, ParticipantKeyHandler>{};
ParticipantKeyHandler? sharedKeyHandler;
var sharedKey = Uint8List(0);

KeyOptions keyProviderOptions = KeyOptions(
  sharedKey: true,
  ratchetSalt: Uint8List.fromList('ratchetSalt'.codeUnits),
  ratchetWindowSize: 16,
  failureTolerance: -1,
);

ParticipantKeyHandler getParticipantKeyHandler(String participantIdentity) {
  if (keyProviderOptions.sharedKey) {
    return getSharedKeyHandler();
  }
  var keys = participantKeys[participantIdentity];
  if (keys == null) {
    keys = ParticipantKeyHandler(
      worker: self,
      participantIdentity: participantIdentity,
      keyOptions: keyProviderOptions,
    );
    if (sharedKey.isNotEmpty) {
      keys.setKey(sharedKey);
    }
    //keys.on(KeyHandlerEvent.KeyRatcheted, emitRatchetedKeys);
    participantKeys[participantIdentity] = keys;
  }
  return keys;
}

FrameCryptor getTrackCryptor(String participantIdentity, String trackId) {
  var cryptor =
      participantCryptors.firstWhereOrNull((c) => c.trackId == trackId);
  if (cryptor == null) {
    logger.info('creating new cryptor for $participantIdentity');
    if (keyProviderOptions == null) {
      throw Exception('Missing keyProvider options');
    }
    cryptor = FrameCryptor(
      worker: self,
      participantIdentity: participantIdentity,
      trackId: trackId,
      keyHandler: getParticipantKeyHandler(participantIdentity),
    );
    //setupCryptorErrorEvents(cryptor);
    participantCryptors.add(cryptor);
  } else if (participantIdentity != cryptor.participantIdentity) {
    // assign new participant id to track cryptor and pass in correct key handler
    cryptor.setParticipant(
        participantIdentity, getParticipantKeyHandler(participantIdentity));
  }
  if (keyProviderOptions.sharedKey) {}
  return cryptor;
}

void unsetCryptorParticipant(String trackId) {
  participantCryptors
      .firstWhereOrNull((c) => c.trackId == trackId)
      ?.unsetParticipant();
}

ParticipantKeyHandler getSharedKeyHandler() {
  sharedKeyHandler ??= ParticipantKeyHandler(
    worker: self,
    participantIdentity: 'shared-key',
    keyOptions: keyProviderOptions,
  );
  return sharedKeyHandler!;
}

void setSharedKey(Uint8List key, {int keyIndex = 0}) {
  logger.info('setting shared key');
  sharedKey = key;
  getSharedKeyHandler().setKey(key, keyIndex: keyIndex);
}

void main() async {
  // configure logs for debugging
  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen((record) {
    print('[${record.loggerName}] ${record.level.name}: ${record.message}');
  });

  logger.info('Worker created');

  if (js_util.getProperty(self, 'RTCTransformEvent') != null) {
    logger.info('setup RTCTransformEvent event handler');
    self.onrtctransform = allowInterop((event) {
      logger.info('Got onrtctransform event');
      var transformer = (event as RTCTransformEvent).transformer;
      transformer.handled = true;
      var options = transformer.options;
      var kind = options.kind;
      var participantId = options.participantId;
      var trackId = options.trackId;
      var codec = options.codec;
      var msgType = options.msgType;

      var cryptor = getTrackCryptor(participantId, trackId);

      cryptor.setupTransform(
          operation: msgType,
          readable: transformer.readable,
          writable: transformer.writable,
          trackId: trackId,
          kind: kind,
          codec: codec);
    });
  }

  self.onMessage.listen((e) {
    var msg = e.data;
    var msgType = msg['msgType'];
    switch (msgType) {
      case 'init':
        var options = msg['keyOptions'];
        keyProviderOptions = KeyOptions(
            sharedKey: options['sharedKey'],
            ratchetSalt: Uint8List.fromList(
                base64Decode(options['ratchetSalt'] as String)),
            ratchetWindowSize: options['ratchetWindowSize'],
            failureTolerance: options['failureTolerance'] ?? -1,
            uncryptedMagicBytes: options['ratchetSalt'] != null
                ? Uint8List.fromList(
                    base64Decode(options['uncryptedMagicBytes'] as String))
                : null);
        logger.config(
            'Init with keyProviderOptions:\n ${keyProviderOptions.toString()}');
        break;
      case 'enable':
        {
          var enabled = msg['enabled'] as bool;
          var participantId = msg['participantId'] as String;
          logger.config('Set enable $enabled for participantId $participantId');
          var cryptors = participantCryptors
              .where((c) => c.participantIdentity == participantId)
              .toList();
          for (var cryptor in cryptors) {
            cryptor.setEnabled(enabled);
          }
          self.postMessage({
            'type': 'cryptorEnabled',
            'participantId': participantId,
            'enable': enabled,
          });
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

          logger.config(
              'SetupTransform for kind $kind, trackId $trackId, participantId $participantId, ${readable.runtimeType} ${writable.runtimeType}}');

          var cryptor = getTrackCryptor(participantId, trackId);

          cryptor.setupTransform(
              operation: msgType,
              readable: readable,
              writable: writable,
              trackId: trackId,
              kind: kind);

          self.postMessage({
            'type': 'cryptorSetup',
            'participantId': participantId,
            'trackId': trackId,
            'exist': exist,
            'operation': msgType,
          });
          cryptor.lastError = CryptorError.kNew;
        }
        break;
      case 'removeTransform':
        {
          var trackId = msg['trackId'] as String;
          logger.config('Removing trackId $trackId');
          unsetCryptorParticipant(trackId);
        }
        break;
      case 'setKey':
      case 'setSharedKey':
        {
          var key = Uint8List.fromList(base64Decode(msg['key'] as String));
          var keyIndex = msg['keyIndex'] as int;
          if (keyProviderOptions.sharedKey) {
            logger.config('Set SharedKey keyIndex $keyIndex');
            setSharedKey(key, keyIndex: keyIndex);
          } else {
            var participantId = msg['participantId'] as String;
            logger.config(
                'Set key for participant $participantId, keyIndex $keyIndex');
            getParticipantKeyHandler(participantId)
                .setKey(key, keyIndex: keyIndex);
          }
        }
        break;
      case 'ratchetKey':
      case 'ratchetSharedKey':
        {
          var keyIndex = msg['keyIndex'];
          var participantId = msg['participantId'] as String;

          if (keyProviderOptions.sharedKey) {
            logger.config('RatchetKey for SharedKey, keyIndex $keyIndex');
            getSharedKeyHandler().ratchetKey(keyIndex);
          } else {
            logger.config(
                'RatchetKey for participant $participantId, keyIndex $keyIndex');
            getParticipantKeyHandler(participantId).ratchetKey(keyIndex);
          }
        }
        break;
      case 'setKeyIndex':
        {
          var keyIndex = msg['index'];
          var participantId = msg['participantId'] as String;
          logger.config('Setup key index for participant $participantId');
          var cryptors = participantCryptors
              .where((c) => c.participantIdentity == participantId)
              .toList();
          for (var c in cryptors) {
            c.setKeyIndex(keyIndex);
          }
        }
        break;
      case 'setSifTrailer':
        {
          var sifTrailer =
              Uint8List.fromList(base64Decode(msg['sifTrailer'] as String));
          keyProviderOptions.uncryptedMagicBytes = sifTrailer;
          logger.config('SetSifTrailer = $sifTrailer');
          for (var c in participantCryptors) {
            c.setSifTrailer(sifTrailer);
          }
        }
        break;
      case 'updateCodec':
        {
          var codec = msg['codec'] as String;
          var trackId = msg['trackId'] as String;
          logger.config('Update codec for trackId $trackId, codec $codec');
          var cryptor =
              participantCryptors.firstWhereOrNull((c) => c.trackId == trackId);
          cryptor?.updateCodec(codec);
        }
        break;
      case 'dispose':
        {
          var trackId = msg['trackId'] as String;
          logger.config('Dispose for trackId $trackId');
          var cryptor =
              participantCryptors.firstWhereOrNull((c) => c.trackId == trackId);
          if (cryptor != null) {
            cryptor.lastError = CryptorError.kDisposed;
            self.postMessage({
              'type': 'cryptorDispose',
              'participantId': cryptor.participantIdentity,
              'trackId': trackId,
            });
          }
        }
        break;
      default:
        logger.warning('Unknown message kind $msg');
    }
  });
}
