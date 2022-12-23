import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:livekit_client/src/e2ee/key_provider.dart';

import '../logger.dart';
import 'utils.dart';

class E2EEManager {
  Room? _room;
  final Map<String, FrameCryptor> _frameCryptors = {};
  final BaseKeyProvider _keyProvider;
  final Algorithm _algorithm = Algorithm.kAesGcm;
  bool _enabled = false;

  E2EEManager(this._keyProvider);

  Future<void> setup(Room room) async {
    if (!isE2EESupported()) {
      logger.warning('E2EE is not supported on this platform.');
      return;
    }

    if (_room != room) {
      _room = room;
      EventsListener<RoomEvent> listener = _room!.createListener();
      listener
        ..on<LocalTrackPublishedEvent>((event) async {
          await _addRtpSender(
              event.publication.track!.sender!, event.publication.sid);
        })
        ..on<LocalTrackUnpublishedEvent>((event) {})
        ..on<TrackSubscribedEvent>((event) async {
          await _addRtpReceiver(event.track.receiver!, event.participant.sid);
        })
        ..on<TrackUnsubscribedEvent>((event) {});
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
  }

  Future<void> setEnabled(bool enabled) async {
    _enabled = enabled;
    for (var frameCryptor in _frameCryptors.values) {
      await frameCryptor.setEnabled(enabled);
    }
  }
}
