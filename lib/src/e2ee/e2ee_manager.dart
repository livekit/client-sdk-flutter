// Copyright 2023 LiveKit, Inc.
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

import 'package:flutter/foundation.dart';

import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../core/room.dart';
import '../e2ee/events.dart';
import '../e2ee/options.dart';
import '../events.dart';
import '../extensions.dart';
import '../managers/event.dart';
import '../utils.dart';
import 'key_provider.dart';

class E2EEManager {
  Room? _room;
  final Map<Map<String, String>, FrameCryptor> _frameCryptors = {};
  final BaseKeyProvider _keyProvider;
  final Algorithm _algorithm = Algorithm.kAesGcm;
  bool _enabled = true;
  EventsListener<RoomEvent>? _listener;
  E2EEManager(this._keyProvider);

  Future<void> setup(Room room) async {
    if (_room != room) {
      await _cleanUp();
      _room = room;
      _listener = _room!.createListener();
      _listener!
        ..on<LocalTrackPublishedEvent>((event) async {
          if (event.publication.encryptionType == EncryptionType.kNone ||
              isSVCCodec(event.publication.track?.codec ?? '')) {
            // no need to setup frame cryptor
            return;
          }
          var frameCryptor = await _addRtpSender(
              sender: event.publication.track!.sender!,
              identity: event.participant.identity,
              sid: event.publication.sid);
          if (kIsWeb && event.publication.track!.codec != null) {
            await frameCryptor.updateCodec(event.publication.track!.codec!);
          }
          frameCryptor.onFrameCryptorStateChanged = (trackId, state) {
            if (kDebugMode) {
              print(
                  'Sender::onFrameCryptorStateChanged: $state, trackId:  $trackId');
            }
            var participant = event.participant;
            [event.participant.events, participant.room.events]
                .emit(TrackE2EEStateEvent(
              participant: participant,
              publication: event.publication,
              state: _e2eeStateFromFrameCryptoState(state),
            ));
          };
        })
        ..on<LocalTrackUnpublishedEvent>((event) async {
          for (var key in _frameCryptors.keys.toList()) {
            if (key.keys.first == event.participant.identity &&
                key.values.first == event.publication.sid) {
              var frameCryptor = _frameCryptors.remove(key);
              await frameCryptor?.setEnabled(false);
              await frameCryptor?.dispose();
            }
          }
        })
        ..on<TrackSubscribedEvent>((event) async {
          var codec = event.publication.mimeType.split('/')[1];
          if (event.publication.encryptionType == EncryptionType.kNone ||
              isSVCCodec(codec)) {
            // no need to setup frame cryptor
            return;
          }
          var frameCryptor = await _addRtpReceiver(
            receiver: event.track.receiver!,
            identity: event.participant.identity,
            sid: event.publication.sid,
          );
          if (kIsWeb) {
            await frameCryptor.updateCodec(codec.toLowerCase());
          }
          frameCryptor.onFrameCryptorStateChanged = (trackId, state) {
            if (kDebugMode) {
              print(
                  'Receiver::onFrameCryptorStateChanged: $state, trackId: $trackId');
            }
            var participant = event.participant;
            [event.participant.events, participant.room.events]
                .emit(TrackE2EEStateEvent(
              participant: participant,
              publication: event.publication,
              state: _e2eeStateFromFrameCryptoState(state),
            ));
          };
        })
        ..on<TrackUnsubscribedEvent>((event) async {
          for (var key in _frameCryptors.keys.toList()) {
            if (key.keys.first == event.participant.identity &&
                key.values.first == event.publication.sid) {
              var frameCryptor = _frameCryptors.remove(key);
              await frameCryptor?.setEnabled(false);
              await frameCryptor?.dispose();
            }
          }
        });
    }
  }

  BaseKeyProvider get keyProvider => _keyProvider;

  Future<void> ratchetKey({String? participantId, int? keyIndex}) async {
    if (participantId != null) {
      var newKey = await _keyProvider.ratchetKey(participantId, keyIndex);
      if (kDebugMode) {
        print('newKey: $newKey');
      }
    } else {
      var newKey = await _keyProvider.ratchetSharedKey(keyIndex: keyIndex);
      if (kDebugMode) {
        print('newKey: $newKey');
      }
    }
  }

  Future<void> _cleanUp() async {
    await _listener?.cancelAll();
    await _listener?.dispose();
    _listener = null;
    for (var frameCryptor in _frameCryptors.values) {
      await frameCryptor.dispose();
    }
    _frameCryptors.clear();
  }

  Future<FrameCryptor> _addRtpSender(
      {required RTCRtpSender sender,
      required String identity,
      required String sid}) async {
    var frameCryptor = await frameCryptorFactory.createFrameCryptorForRtpSender(
        participantId: identity,
        sender: sender,
        algorithm: _algorithm,
        keyProvider: _keyProvider.keyProvider);
    _frameCryptors[{identity: sid}] = frameCryptor;
    await frameCryptor.setEnabled(_enabled);
    await frameCryptor.setKeyIndex(0);
    return frameCryptor;
  }

  Future<FrameCryptor> _addRtpReceiver(
      {required RTCRtpReceiver receiver,
      required String identity,
      required String sid}) async {
    var frameCryptor =
        await frameCryptorFactory.createFrameCryptorForRtpReceiver(
            participantId: identity,
            receiver: receiver,
            algorithm: _algorithm,
            keyProvider: _keyProvider.keyProvider);
    _frameCryptors[{identity: sid}] = frameCryptor;
    await frameCryptor.setEnabled(_enabled);
    await frameCryptor.setKeyIndex(0);
    return frameCryptor;
  }

  Future<void> setEnabled(bool enabled) async {
    _enabled = enabled;
    for (var frameCryptor in _frameCryptors.entries) {
      await frameCryptor.value.setEnabled(enabled);
    }
  }

  E2EEState _e2eeStateFromFrameCryptoState(FrameCryptorState state) {
    switch (state) {
      case FrameCryptorState.FrameCryptorStateNew:
        return E2EEState.kNew;
      case FrameCryptorState.FrameCryptorStateOk:
        return E2EEState.kOk;
      case FrameCryptorState.FrameCryptorStateMissingKey:
        return E2EEState.kMissingKey;
      case FrameCryptorState.FrameCryptorStateEncryptionFailed:
        return E2EEState.kEncryptionFailed;
      case FrameCryptorState.FrameCryptorStateDecryptionFailed:
        return E2EEState.kDecryptionFailed;
      case FrameCryptorState.FrameCryptorStateInternalError:
        return E2EEState.kInternalError;
      case FrameCryptorState.FrameCryptorStateKeyRatcheted:
        return E2EEState.kKeyRatcheted;
    }
  }
}
