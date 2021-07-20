import 'package:flutter_webrtc/flutter_webrtc.dart';

/// a wrapper around PeerConnection
class PCTransport {
  RTCPeerConnection pc;
  List<RTCIceCandidate> pendingCandidates = [];
  bool restartingIce = false;

  PCTransport(this.pc);

  Future<void> setRemoteDescription(RTCSessionDescription sd) async {
    await pc.setRemoteDescription(sd);

    Future.forEach<RTCIceCandidate>(pendingCandidates, (candidate) async {
      await pc.addCandidate(candidate);
    });
  }

  Future<void> addIceCandidate(RTCIceCandidate candidate) async {
    var desc = await pc.getRemoteDescription();
    if (desc != null && !restartingIce) {
      return pc.addCandidate(candidate);
    }
    pendingCandidates.add(candidate);
  }
}
