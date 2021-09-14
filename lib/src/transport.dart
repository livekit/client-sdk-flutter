import 'dart:async';

import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;

import 'logger.dart';
import 'types.dart';
import 'utils.dart';

typedef PCTransportOnOffer = void Function(rtc.RTCSessionDescription offer);

/// a wrapper around PeerConnection
class PCTransport {
  final rtc.RTCPeerConnection pc;
  final List<rtc.RTCIceCandidate> _pendingCandidates = [];
  bool restartingIce = false;
  bool renegotiate = false;
  PCTransportOnOffer? onOffer;
  Function? _cancelDebounce;

  // private constructor
  PCTransport._(this.pc);

  static Future<PCTransport> create(Map<String, dynamic> configuration) async {
    final _ = await rtc.createPeerConnection(configuration);
    return PCTransport._(_);
  }

  late final negotiate = Utils.createDebounceFunc(
    () => createAndSendOffer(),
    cancelFunc: (f) => _cancelDebounce = f,
    wait: const Duration(milliseconds: 100),
  );

  Future<void> dispose() async {
    // Ensure debounce won't fire
    _cancelDebounce?.call();
    _cancelDebounce = null;

    // Ensure callbacks won't fire any more
    pc.onRenegotiationNeeded = null;
    pc.onIceCandidate = null;
    pc.onIceConnectionState = null;
    pc.onTrack = null;

    // Remove all senders
    List<rtc.RTCRtpSender> senders = [];
    try {
      senders = await pc.getSenders();
    } catch (_) {
      logger.warning('getSenders() failed with error: $_');
    }

    for (final e in senders) {
      try {
        await pc.removeTrack(e);
      } catch (_) {
        logger.warning('removeTrack() failed with error: $_');
      }
    }

    await pc.close();
    await pc.dispose();
  }

  Future<void> setRemoteDescription(rtc.RTCSessionDescription sd) async {
    await pc.setRemoteDescription(sd);

    for (final candidate in _pendingCandidates) {
      await pc.addCandidate(candidate);
    }

    _pendingCandidates.clear();
    restartingIce = false;

    if (renegotiate) {
      renegotiate = false;
      await createAndSendOffer(); // await or un-awaited ?
    }
  }

  Future<void> createAndSendOffer([RTCOfferOptions? options]) async {
    if (onOffer == null) {
      return;
    }

    if (options?.iceRestart ?? false) {
      logger.fine('restarting ICE');
      restartingIce = true;
    }

    if (pc.signalingState == rtc.RTCSignalingState.RTCSignalingStateHaveLocalOffer) {
      // we're waiting for the peer to accept our offer, so we'll just wait
      // the only exception to this is when ICE restart is needed
      final currentSD = await getRemoteDescription();
      if ((options?.iceRestart ?? false) && currentSD != null) {
        // TODO: handle when ICE restart is needed but we don't have a remote description
        // the best thing to do is to recreate the peerconnection
        await pc.setRemoteDescription(currentSD);
      } else {
        renegotiate = true;
        return;
      }
    }

    // actually negotiate
    logger.fine('starting to negotiate');
    final offer = await pc.createOffer(options?.toMap() ?? <String, dynamic>{});
    await pc.setLocalDescription(offer);
    onOffer?.call(offer);
  }

  Future<void> addIceCandidate(rtc.RTCIceCandidate candidate) async {
    final desc = await getRemoteDescription();

    if (desc != null && !restartingIce) {
      await pc.addCandidate(candidate);
      return;
    }

    _pendingCandidates.add(candidate);
  }

  Future<rtc.RTCSessionDescription?> getRemoteDescription() async {
    // Checking agains null doesn't work as intended
    // if (pc.iceConnectionState == null) return null;

    try {
      final result = await pc.getRemoteDescription();
      logger.fine('pc.getRemoteDescription $result');
      return result;
    } catch (_) {
      logger.warning('pc.getRemoteDescription failed with error: $_');
    }
  }
}
