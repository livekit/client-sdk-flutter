// Copyright 2024 LiveKit, Inc.
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

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;
import 'package:meta/meta.dart';
import 'package:sdp_transform/sdp_transform.dart' as sdp_transform;

import '../exceptions.dart';
import '../extensions.dart';
import '../internal/types.dart';
import '../logger.dart';
import '../options.dart';
import '../support/disposable.dart';
import '../support/platform.dart';
import '../types/other.dart';
import '../utils.dart';

const ddExtensionURI = 'https://aomediacodec.github.io/av1-rtp-spec/#dependency-descriptor-rtp-header-extension';

/*
 * Video codecs use a very low bitrate at the beginning and increase slowly by
 * the bandwidth estimator until they reach the target bitrate. The process commonly
 * costs more than 10 seconds causing subscribers to get blurry video at the first
 * few seconds. We use x-google-start-bitrate to hint the BWE to start higher.
 *
 * Why 90%: Gives ~10% headroom for bandwidth estimation while starting close to target.
 * Why same for all codecs: Target bitrate already accounts for codec efficiency
 * (e.g., users set lower targets for VP9/AV1 knowing they're more efficient).
 * Why cap at 1 Mbps: Prevents BWE from starting too aggressively on high bitrate tracks.
 */
const startBitrateMultiplier = 0.9;

/// Maximum x-google-start-bitrate in kbps. 1 Mbps prevents BWE from starting too aggressively.
const maxStartBitrateKbps = 1000;

/// Minimum target bitrate in kbps for the start bitrate hint. Below this, seeding above the
/// real capacity costs more than the ramp it saves, so libwebrtc's default is left in place.
const minTargetBitrateKbps = 300;

class TrackBitrateInfo {
  String? cid;
  rtc.RTCRtpTransceiver? transceiver;
  String codec;
  int maxbr;
  bool isScreenShare;
  TrackBitrateInfo({
    required this.cid,
    required this.transceiver,
    required this.codec,
    required this.maxbr,
    this.isScreenShare = false,
  });
}

/// Codec payload for [codec] in this media section, when the section carries [cid].
///
/// Returns `null` when the section does not belong to the track, `0` when it does but does
/// not offer the requested codec, and the codec payload otherwise.
@internal
int? findTrackCodecPayload(Map<String, dynamic> media, String cid, String codec) {
  final msid = media['msid'];
  if (msid is! String || !msid.contains(cid)) {
    return null;
  }
  for (final rtp in (media['rtp'] as List? ?? const [])) {
    if ((rtp['codec'] as String?)?.toUpperCase() == codec.toUpperCase()) {
      return rtp['payload'] as int;
    }
  }
  return 0;
}

/// Start bitrate hinted for a single track, or `null` when its target is too low to be
/// worth seeding.
///
/// 90% of the target leaves ~10% headroom for the estimator to settle. The same multiplier
/// is used for every codec because the target already reflects the codec's efficiency.
/// Camera is capped at 1 Mbps so the estimator does not open too aggressively on a
/// high-bitrate track; screen share is exempt, because its content needs the bitrate
/// immediately to stay legible.
@internal
int? computeTrackStartBitrate(TrackBitrateInfo trackbr) {
  if (trackbr.maxbr < minTargetBitrateKbps) {
    return null;
  }
  final calculated = (trackbr.maxbr * startBitrateMultiplier).round();
  return trackbr.isScreenShare ? calculated : math.min(calculated, maxStartBitrateKbps);
}

/// The single start bitrate for this peer connection: the largest hint among the video
/// m-sections of [media] that map to a published track.
///
/// libwebrtc reads `x-google-start-bitrate` per m-section but applies it to the shared
/// `Call` (`WebRtcVideoSendChannel::ApplyChangedParams` -> `SetSdpBitrateParameters`), where
/// `RtpBitrateConfigurator` holds one config for the whole connection. Differing per-section
/// values are therefore last-writer-wins, decided by m-section order, so every video section
/// gets the same number instead.
///
/// Only sections that can send local media are considered. [trackBitrates] is append-only and
/// an unpublished section keeps its `a=msid`, so matching on msid alone would still pair a
/// stale entry with its old section — letting an uncapped screen-share target seed a
/// connection that now carries only a camera, or consuming the one-shot hint on a section that
/// sends nothing. `recvonly` and `inactive` are the only directions that cannot carry local
/// media, and they are exactly where a section lands once its sender is removed (`removeTrack`
/// moves sendonly to inactive and sendrecv to recvonly); everything else sends, including a
/// section with no direction attribute, which SDP defaults to `sendrecv`.
@internal
int? computeConnectionStartBitrate(List<dynamic> media, List<TrackBitrateInfo> trackBitrates) {
  int? connectionStartBitrate;
  for (final m in media) {
    final direction = m['direction'];
    if (m['type'] != 'video' || direction == 'recvonly' || direction == 'inactive') {
      continue;
    }
    for (final trackbr in trackBitrates) {
      final cid = trackbr.cid;
      if (cid == null) {
        continue;
      }
      final codecPayload = findTrackCodecPayload(m, cid, trackbr.codec);
      if (codecPayload == null) {
        continue;
      }
      final startBitrate = codecPayload > 0 ? computeTrackStartBitrate(trackbr) : null;
      if (startBitrate != null && (connectionStartBitrate == null || startBitrate > connectionStartBitrate)) {
        connectionStartBitrate = startBitrate;
      }
      break;
    }
  }
  return connectionStartBitrate;
}

/// Declares `x-google-start-bitrate` on [codecPayload]'s fmtp. This SDP munging is used for a
/// bitrate setting that cannot be applied through the sender's encodings.
///
/// Returns whether the section now carries the hint.
@internal
bool applyVideoStartBitrate(Map<String, dynamic> media, int codecPayload, int startBitrate) {
  final fmtpList = (media['fmtp'] as List? ?? const []);
  for (final fmtp in fmtpList) {
    if (fmtp['payload'] == codecPayload) {
      // A payload type is shared across the bundle, so a value written for one section is
      // already the connection-level one; leave it rather than rewrite it.
      if (!(fmtp['config'] as String).contains('x-google-start-bitrate')) {
        fmtp['config'] += ';x-google-start-bitrate=$startBitrate';
      }
      return true;
    }
  }
  // VP8 and some codecs may not have an existing fmtp line.
  fmtpList.add(<String, dynamic>{
    'payload': codecPayload,
    'config': 'x-google-start-bitrate=$startBitrate',
  });
  media['fmtp'] = fmtpList;
  return true;
}

typedef TransportOnOffer = void Function(rtc.RTCSessionDescription offer);
typedef PeerConnectionCreate =
    Future<rtc.RTCPeerConnection> Function(Map<String, dynamic> configuration, [Map<String, dynamic> constraints]);

/// a wrapper around PeerConnection
class Transport extends Disposable {
  final rtc.RTCPeerConnection pc;
  final List<rtc.RTCIceCandidate> _pendingCandidates = [];
  final List<TrackBitrateInfo> _bitrateTrackers = [];

  /// Whether an offer carrying the connection-level `x-google-start-bitrate` has been
  /// accepted locally. The hint is written once per peer connection: libwebrtc retains
  /// `start_bitrate_bps` in `RtpBitrateConfigurator` and re-applies it on network route
  /// changes, so a later rewrite is at best a no-op and at worst restarts a converged
  /// bandwidth estimator. A new peer connection (full reconnect) seeds a new estimator.
  bool _hasAppliedVideoStartBitrate = false;

  bool restartingIce = false;
  bool renegotiate = false;
  TransportOnOffer? onOffer;
  Function? _cancelDebounce;
  ConnectOptions connectOptions;

  // private constructor
  Transport._(this.pc, this.connectOptions) {
    //
    onDispose(() async {
      _cancelDebounce?.call();
      _cancelDebounce = null;

      // Ensure callbacks won't fire any more
      pc.onRenegotiationNeeded = null;
      pc.onIceCandidate = null;
      pc.onConnectionState = null;
      pc.onIceConnectionState = null;
      pc.onTrack = null;

      // Remove all senders
      List<rtc.RTCRtpSender> senders = [];
      try {
        senders = await pc.getSenders();
      } catch (err) {
        logger.warning('getSenders() failed with error: $err');
      }

      for (final e in senders) {
        try {
          await pc.removeTrack(e);
        } catch (err) {
          logger.warning('removeTrack() failed with error: $err');
        }
      }

      await pc.close();
      await pc.dispose();
    });
  }

  static Future<Transport> create(
    PeerConnectionCreate peerConnectionCreate, {
    RTCConfiguration? rtcConfig,
    required ConnectOptions connectOptions,
  }) async {
    rtcConfig ??= const RTCConfiguration();
    logger.fine('[PCTransport] creating ${rtcConfig.toMap()}');
    final pc = await peerConnectionCreate(rtcConfig.toMap());
    return Transport._(pc, connectOptions);
  }

  late final negotiate = Utils.createDebounceFunc(
    (void _) => createAndSendOffer(),
    cancelFunc: (f) => _cancelDebounce = f,
    wait: connectOptions.timeouts.debounce,
  );

  Future<void> setRemoteDescription(rtc.RTCSessionDescription sd) async {
    if (isDisposed) {
      logger.warning('[$objectId] setRemoteDescription() already disposed');
      return;
    }

    try {
      await pc.setRemoteDescription(sd);
    } catch (e) {
      logger.warning('[$objectId] setRemoteDescription() failed with error: $e');
    }

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

    if (await pc.getSignalingState() == rtc.RTCSignalingState.RTCSignalingStateHaveLocalOffer) {
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

    if (restartingIce && !lkPlatformIs(PlatformType.web)) {
      await pc.restartIce();
    }

    // actually negotiate
    logger.fine('starting to negotiate');
    final offer = await pc.createOffer(options?.toMap() ?? <String, dynamic>{});

    if ((offer.sdp ?? '').contains('goog-sped-v1')) {
      logger.fine('negotiate with sped (WARP)');
    }

    final sdpParsed = sdp_transform.parse(offer.sdp ?? '');
    // One value for every video m-section, written only on the first offer that carries local
    // video: the hint is connection-level in libwebrtc, so differing per-section values would
    // be last-writer-wins on m-section order. Offers before any video is published (data
    // channel or audio only) find no target and leave the latch unset.
    final connectionStartBitrate = _hasAppliedVideoStartBitrate
        ? null
        : computeConnectionStartBitrate(sdpParsed['media'] ?? const [], _bitrateTrackers);
    var appliedVideoStartBitrate = false;
    sdpParsed['media']?.forEach((media) {
      if (media['type'] == 'video') {
        ensureVideoDDExtensionForSVC(media, media['type'], media['port'], media['protocol'], media['payloads']);

        // mung sdp for codec bitrate setting that can't apply by sendEncoding
        for (var trackbr in _bitrateTrackers) {
          final cid = trackbr.cid;
          if (cid == null) {
            continue;
          }
          final codecPayload = findTrackCodecPayload(media, cid, trackbr.codec);
          if (codecPayload == null) {
            continue;
          }
          if (codecPayload > 0 && connectionStartBitrate != null) {
            appliedVideoStartBitrate =
                applyVideoStartBitrate(media, codecPayload, connectionStartBitrate) || appliedVideoStartBitrate;
          }
          break;
        }
      }
    });

    final mungedSdp = sdp_transform.write(sdpParsed, null);
    try {
      await setMungedSDP(sd: offer, munged: mungedSdp);
    } catch (e) {
      throw NegotiationError(e.toString());
    }
    // setMungedSDP falls back to the unmunged SDP on rejection. Only consume the one-shot
    // hint once the SDP carrying it has been accepted locally.
    if (appliedVideoStartBitrate && offer.sdp == mungedSdp) {
      _hasAppliedVideoStartBitrate = true;
    }
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
      return result;
    } catch (err) {
      logger.warning('pc.getRemoteDescription failed with error: $err');
    }
    return null;
  }

  void setTrackBitrateInfo(TrackBitrateInfo info) {
    _bitrateTrackers.add(info);
  }

  bool ensureVideoDDExtensionForSVC(
    Map<String, dynamic> media,
    String? type,
    num port,
    String protocol,
    String? payloads,
  ) {
    final codec = media['rtp']?[0]?['codec']?.toLowerCase();
    if (!isSVCCodec(codec)) {
      return false;
    }

    var maxID = 0;
    bool ddFound = false;
    final List<dynamic>? ext = media['ext'];
    if (ext != null) {
      for (var e in ext) {
        if (e['uri'] == ddExtensionURI) {
          ddFound = true;
          continue;
        }
        if (e['value'] > maxID) {
          maxID = e['value'];
        }
      }
    }

    if (!ddFound) {
      ext?.add({
        'value': maxID + 1,
        'uri': ddExtensionURI,
      });
    }

    return ddFound;
  }

  Future<void> setMungedSDP({required rtc.RTCSessionDescription sd, String? munged, bool? remote}) async {
    if (munged != null) {
      final originalSdp = sd.sdp;
      sd.sdp = munged;
      try {
        logger.fine('setting munged ${remote == true ? 'remote' : 'local'}');
        logger.finer('description munged: $munged ');
        if (remote == true) {
          await pc.setRemoteDescription(sd);
        } else {
          await pc.setLocalDescription(sd);
        }
        return;
      } catch (e) {
        logger.warning('not able to set ${sd.type}, falling back to unmodified sdp error: $e, sdp: $munged ');
        sd.sdp = originalSdp;
      }
    }

    try {
      if (remote == true) {
        await pc.setRemoteDescription(sd);
      } else {
        await pc.setLocalDescription(sd);
      }
    } catch (e) {
      // this error cannot always be caught.ght
      logger.warning('unable to set ${sd.type}, error: $e, sdp: ${sd.sdp}');
      rethrow;
    }
  }
}
