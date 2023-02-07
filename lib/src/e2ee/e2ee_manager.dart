import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:livekit_client/src/e2ee/events.dart';
import 'package:livekit_client/src/extensions.dart';

import '../events.dart';
import '../core/room.dart';
import '../managers/event.dart';
import 'key_provider.dart';

class E2EEManager {
  Room? _room;
  final Map<String, FrameCryptor> _frameCryptors = {};
  final BaseKeyProvider _keyProvider;
  final Algorithm _algorithm = Algorithm.kAesGcm;
  bool _enabled = true;
  EventsListener<RoomEvent>? _listener;
  E2EEManager(this._keyProvider);

  Future<void> setup(Room room) async {
    if (_room != room) {
      _room = room;
      _listener = _room!.createListener();
      _listener!
        ..on<LocalTrackPublishedEvent>((event) async {
          var trackId = event.publication.sid;
          var participantId = event.participant.sid;
          var frameCryptor = await _addRtpSender(
              event.publication.track!.sender!, participantId, trackId);
          event.participant.enabledE2EE = true;
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
            event.participant.enabledE2EE =
                state == FrameCryptorState.FrameCryptorStateOk;
          };
        })
        ..on<LocalTrackUnpublishedEvent>((event) async {
          var trackId = event.publication.sid;
          var frameCryptor = _frameCryptors.remove(trackId);
          await frameCryptor?.dispose();
        })
        ..on<TrackSubscribedEvent>((event) async {
          var trackId = event.publication.sid;
          var participantId = event.participant.sid;
          var frameCryptor = await _addRtpReceiver(
              event.track.receiver!, participantId, trackId);
          event.participant.enabledE2EE = true;
          if (kIsWeb) {
            var codec = event.publication.mimeType.split('/')[1];
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

            event.participant.enabledE2EE =
                state == FrameCryptorState.FrameCryptorStateOk;
          };
        })
        ..on<TrackUnsubscribedEvent>((event) async {
          var trackId = event.publication.sid;
          var frameCryptor = _frameCryptors.remove(trackId);
          await frameCryptor?.dispose();
        });
    }
  }

  Future<FrameCryptor> _addRtpSender(
      RTCRtpSender sender, String participantId, String trackId) async {
    var frameCryptor = await FrameCryptorFactory.instance
        .createFrameCryptorForRtpSender(
            participantId: participantId,
            sender: sender,
            algorithm: _algorithm,
            keyManager: _keyProvider.keyManager);
    _frameCryptors[trackId] = frameCryptor;
    await frameCryptor.setEnabled(_enabled);
    if (_keyProvider.isSharedKey) {
      await _keyProvider.keyManager.setKey(
          participantId: participantId, index: 0, key: _keyProvider.sharedKey);
      await frameCryptor.setKeyIndex(0);
    }
    return frameCryptor;
  }

  Future<FrameCryptor> _addRtpReceiver(
      RTCRtpReceiver receiver, String participantId, String trackId) async {
    var frameCryptor = await FrameCryptorFactory.instance
        .createFrameCryptorForRtpReceiver(
            participantId: participantId,
            receiver: receiver,
            algorithm: _algorithm,
            keyManager: _keyProvider.keyManager);
    _frameCryptors[trackId] = frameCryptor;
    await frameCryptor.setEnabled(_enabled);
    if (_keyProvider.isSharedKey) {
      await _keyProvider.keyManager.setKey(
          participantId: participantId, index: 0, key: _keyProvider.sharedKey);
      await frameCryptor.setKeyIndex(0);
    }
    return frameCryptor;
  }

  Future<void> setEnabled(bool enabled) async {
    _enabled = enabled;
    for (var frameCryptor in _frameCryptors.entries) {
      await frameCryptor.value.setEnabled(enabled);
      if (_keyProvider.isSharedKey) {
        await _keyProvider.keyManager.setKey(
            participantId: frameCryptor.key,
            index: 0,
            key: _keyProvider.sharedKey);
        await frameCryptor.value.setKeyIndex(0);
      }
    }
  }

  E2EEStateState _e2eeStateFromFrameCryptoState(FrameCryptorState state) {
    switch (state) {
      case FrameCryptorState.FrameCryptorStateNew:
        return E2EEStateState.kNew;
      case FrameCryptorState.FrameCryptorStateOk:
        return E2EEStateState.kOk;
      case FrameCryptorState.FrameCryptorStateMissingKey:
        return E2EEStateState.kMissingKey;
      case FrameCryptorState.FrameCryptorStateEncryptionFailed:
        return E2EEStateState.kEncryptionFailed;
      case FrameCryptorState.FrameCryptorStateDecryptionFailed:
        return E2EEStateState.kDecryptionFailed;
      case FrameCryptorState.FrameCryptorStateInternalError:
        return E2EEStateState.kInternalError;
    }
  }
}
