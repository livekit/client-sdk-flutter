import 'package:flutter_webrtc/flutter_webrtc.dart';

/// a wrapper around PeerConnection
class PCTransport {
  RTCPeerConnection pc;
  List<RTCIceCandidate> pendingCandidates = [];
  bool restartingIce = false;

  PCTransport(this.pc);

  Future<void> setRemoteDescription(RTCSessionDescription sd) async {
    await pc.setRemoteDescription(sd);

    await Future.forEach<RTCIceCandidate>(pendingCandidates, (candidate) async {
      await pc.addCandidate(candidate);
    });

    pendingCandidates.clear();
    restartingIce = false;
  }

  Future<void> addIceCandidate(RTCIceCandidate candidate) async {
    final desc = await getRemoteDescription();
    if (desc != null && !restartingIce) {
      return pc.addCandidate(candidate);
    }
    pendingCandidates.add(candidate);
  }

  Future<RTCSessionDescription?> getRemoteDescription() async {
    if (pc.iceConnectionState == null) {
      return null;
    }
    return pc.getRemoteDescription();
  }
}
