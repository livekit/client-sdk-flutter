import 'dart:async';

import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;

import '../constants.dart';
import '../extensions.dart';
import '../internal/types.dart';
import '../logger.dart';
import '../support/disposable.dart';
import '../types/other.dart';
import '../utils.dart';

typedef TransportOnOffer = void Function(rtc.RTCSessionDescription offer);
typedef PeerConnectionCreate = Future<rtc.RTCPeerConnection> Function(
    Map<String, dynamic> configuration,
    [Map<String, dynamic> constraints]);

/// a wrapper around PeerConnection
class Transport extends Disposable {
  final rtc.RTCPeerConnection pc;
  final List<rtc.RTCIceCandidate> _pendingCandidates = [];
  bool restartingIce = false;
  bool renegotiate = false;
  TransportOnOffer? onOffer;
  Function? _cancelDebounce;

  // private constructor
  Transport._(this.pc) {
    //
    onDispose(() async {
      _cancelDebounce?.call();
      _cancelDebounce = null;

      // Ensure callbacks won't fire any more
      pc.onRenegotiationNeeded = null;
      pc.onIceCandidate = null;
      pc.onConnectionState = null;
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
    });
  }

  static Future<Transport> create(PeerConnectionCreate peerConnectionCreate,
      [RTCConfiguration? rtcConfig]) async {
    rtcConfig ??= const RTCConfiguration();
    logger.fine('[PCTransport] creating ${rtcConfig.toMap()}');
    final _ = await peerConnectionCreate(rtcConfig.toMap());
    return Transport._(_);
  }

  late final negotiate = Utils.createDebounceFunc(
    (void _) => createAndSendOffer(),
    cancelFunc: (f) => _cancelDebounce = f,
    wait: Timeouts.debounce,
  );

  Future<void> setRemoteDescription(rtc.RTCSessionDescription sd) async {
    if (isDisposed) {
      logger.warning('[$objectId] setRemoteDescription() already disposed');
      return;
    }

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
    if (isDisposed) {
      logger.warning('[$objectId] createAndSendOffer() already disposed');
      return;
    }

    if (onOffer == null) {
      logger.warning('onOffer is null');
      return;
    }

    if (options?.iceRestart ?? false) {
      logger.fine('restarting ICE');
      restartingIce = true;
    }

    if (pc.signalingState ==
        rtc.RTCSignalingState.RTCSignalingStateHaveLocalOffer) {
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
    if (isDisposed) {
      logger.warning('[$objectId] addIceCandidate() already disposed');
      return;
    }

    final desc = await getRemoteDescription();

    if (desc != null && !restartingIce) {
      await pc.addCandidate(candidate);
      return;
    }

    _pendingCandidates.add(candidate);
  }

  Future<rtc.RTCSessionDescription?> getRemoteDescription() async {
    if (isDisposed) {
      logger.warning('[$objectId] getRemoteDescription() already disposed');
      return null;
    }

    // Checking agains null doesn't work as intended
    // if (pc.iceConnectionState == null) return null;

    try {
      final result = await pc.getRemoteDescription();
      logger.fine('pc.getRemoteDescription $result');
      return result;
    } catch (_) {
      logger.warning('pc.getRemoteDescription failed with error: $_');
    }
    return null;
  }
}
