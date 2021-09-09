import 'package:flutter_webrtc/flutter_webrtc.dart';

import 'logger.dart';

/// a wrapper around PeerConnection
class PCTransport {
  final RTCPeerConnection pc;
  final List<RTCIceCandidate> _pendingCandidates = [];
  bool restartingIce = false;

  PCTransport(this.pc);

  Future<void> dispose() async {
    // Ensure callbacks won't fire any more
    pc.onRenegotiationNeeded = null;
    pc.onIceCandidate = null;
    pc.onIceConnectionState = null;
    pc.onTrack = null;

    List<RTCRtpSender> senders = [];
    try {
      senders = await pc.getSenders();
    } catch (_) {}

    for (final e in senders) {
      try {
        await pc.removeTrack(e);
      } catch (_) {}
    }

    await pc.close();
    await pc.dispose();
  }

  Future<void> setRemoteDescription(RTCSessionDescription sd) async {
    await pc.setRemoteDescription(sd);

    await Future.forEach<RTCIceCandidate>(_pendingCandidates, (candidate) async {
      await pc.addCandidate(candidate);
    });

    _pendingCandidates.clear();
    restartingIce = false;
  }

  Future<void> addIceCandidate(RTCIceCandidate candidate) async {
    final desc = await getRemoteDescription();

    if (desc != null && !restartingIce) {
      await pc.addCandidate(candidate);
      return;
    }

    _pendingCandidates.add(candidate);
  }

  Future<RTCSessionDescription?> getRemoteDescription() async {
    // Checking agains null doesn't work as intended
    // if (pc.iceConnectionState == null) return null;
    try {
      final result = await pc.getRemoteDescription();
      logger.fine('pc.getRemoteDescription $result');
      return result;
    } catch (_) {
      logger.warning('pc.getRemoteDescription did throw: $_');
    }
  }
}
