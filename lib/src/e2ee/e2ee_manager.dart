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
  final List<FrameCryptor> _senderFrameCryptors = [];
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
          var trackId = event.publication.sid;
          var participantId = event.participant.sid;
          var frameCryptor = await _addRtpSender(
              event.publication.track!.sender!,
              participantId,
              trackId,
              event.publication.track!.kind.name.toLowerCase());
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
          _senderFrameCryptors.add(frameCryptor);
        })
        ..on<LocalTrackUnpublishedEvent>((event) async {
          var trackId = event.publication.sid;
          var frameCryptor = _frameCryptors.remove(trackId);
          _senderFrameCryptors.remove(frameCryptor);
          await frameCryptor?.dispose();
        })
        ..on<TrackSubscribedEvent>((event) async {
          var trackId = event.publication.sid;
          var participantId = event.participant.sid;
          var frameCryptor = await _addRtpReceiver(event.track.receiver!,
              participantId, trackId, event.track.kind.name.toLowerCase());
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
          };
        })
        ..on<TrackUnsubscribedEvent>((event) async {
          var trackId = event.publication.sid;
          var frameCryptor = _frameCryptors.remove(trackId);
          await frameCryptor?.dispose();
        });
    }
  }

  Future<void> ratchetKey() async {
    for (var frameCryptor in _senderFrameCryptors) {
      var newKey = await _keyProvider.ratchetKey(frameCryptor.participantId, 0);
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

  Future<FrameCryptor> _addRtpSender(RTCRtpSender sender, String participantId,
      String trackId, String kind) async {
    var pid = '$kind-sender-$participantId-$trackId';
    var frameCryptor = await FrameCryptorFactory.instance
        .createFrameCryptorForRtpSender(
            participantId: pid,
            sender: sender,
            algorithm: _algorithm,
            keyProvider: _keyProvider.keyProvider);
    _frameCryptors[trackId] = frameCryptor;
    await frameCryptor.setEnabled(_enabled);
    if (_keyProvider.options.sharedKey) {
      await _keyProvider.keyProvider
          .setKey(participantId: pid, index: 0, key: _keyProvider.sharedKey!);
      await frameCryptor.setKeyIndex(0);
    }
    return frameCryptor;
  }

  Future<FrameCryptor> _addRtpReceiver(RTCRtpReceiver receiver,
      String participantId, String trackId, String kind) async {
    var pid = '$kind-receiver-$participantId-$trackId';
    var frameCryptor = await FrameCryptorFactory.instance
        .createFrameCryptorForRtpReceiver(
            participantId: pid,
            receiver: receiver,
            algorithm: _algorithm,
            keyProvider: _keyProvider.keyProvider);
    _frameCryptors[trackId] = frameCryptor;
    await frameCryptor.setEnabled(_enabled);
    if (_keyProvider.options.sharedKey) {
      await _keyProvider.keyProvider
          .setKey(participantId: pid, index: 0, key: _keyProvider.sharedKey!);
      await frameCryptor.setKeyIndex(0);
    }
    return frameCryptor;
  }

  Future<void> setEnabled(bool enabled) async {
    _enabled = enabled;
    for (var frameCryptor in _frameCryptors.entries) {
      await frameCryptor.value.setEnabled(enabled);
      if (_keyProvider.options.sharedKey) {
        await _keyProvider.keyProvider.setKey(
            participantId: frameCryptor.key,
            index: 0,
            key: _keyProvider.sharedKey!);
        await frameCryptor.value.setKeyIndex(0);
      }
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
