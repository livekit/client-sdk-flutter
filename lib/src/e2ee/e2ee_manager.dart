import 'package:flutter_webrtc/flutter_webrtc.dart';

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
          await _addRtpSender(
              event.publication.track!.sender!, event.publication.sid);
          event.participant.enabledE2EE = true;
        })
        ..on<LocalTrackUnpublishedEvent>((event) async {
          var frameCryptor = _frameCryptors.remove(event.participant.sid);
          await frameCryptor!.dispose();
        })
        ..on<TrackSubscribedEvent>((event) async {
          await _addRtpReceiver(event.track.receiver!, event.participant.sid);
          event.participant.enabledE2EE = true;
        })
        ..on<TrackUnsubscribedEvent>((event) async {
          var frameCryptor = _frameCryptors.remove(event.participant.sid);
          await frameCryptor!.dispose();
        });
    }
  }

  Future<void> _addRtpSender(RTCRtpSender sender, String participantId) async {
    var frameCryptor = await FrameCryptorFactory.instance
        .createFrameCryptorForRtpSender(
            participantId: participantId,
            sender: sender,
            algorithm: _algorithm,
            keyManager: _keyProvider.keyManager);
    _frameCryptors[participantId] = frameCryptor;
    await frameCryptor.setEnabled(_enabled);
    if (_keyProvider.isSharedKey) {
      await _keyProvider.keyManager.setKey(
          participantId: participantId, index: 0, key: _keyProvider.sharedKey);
      await frameCryptor.setKeyIndex(0);
    }
  }

  Future<void> _addRtpReceiver(
      RTCRtpReceiver receiver, String participantId) async {
    var frameCryptor = await FrameCryptorFactory.instance
        .createFrameCryptorForRtpReceiver(
            participantId: participantId,
            receiver: receiver,
            algorithm: _algorithm,
            keyManager: _keyProvider.keyManager);
    _frameCryptors[participantId] = frameCryptor;
    await frameCryptor.setEnabled(_enabled);
    if (_keyProvider.isSharedKey) {
      await _keyProvider.keyManager.setKey(
          participantId: participantId, index: 0, key: _keyProvider.sharedKey);
      await frameCryptor.setKeyIndex(0);
    }
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
}
