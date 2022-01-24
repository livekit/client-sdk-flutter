import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import '../extensions.dart';
import '../logger.dart';
import '../participant/local.dart';
import '../proto/livekit_models.pb.dart' as lk_models;
import '../proto/livekit_rtc.pb.dart' as lk_rtc;
import '../track/local/local.dart';
import 'track_publication.dart';

/// A [TrackPublication] which belongs to the [LocalParticipant].
class LocalTrackPublication<T extends LocalTrack> extends TrackPublication<T> {
  /// The [LocalParticipant] this instance belongs to.
  @override
  final LocalParticipant participant;

  LocalTrackPublication({
    required this.participant,
    required lk_models.TrackInfo info,
    required T track,
  }) : super(info: info) {
    updateTrack(track);
    // register dispose func
    onDispose(() async {
      // this object is responsible for disposing track
      await this.track?.dispose();
    });
  }

  /// Mute the track associated with this publication
  Future<void> mute() async => await track?.mute();

  /// Unmute the track associated with this publication
  Future<void> unmute() async => await track?.unmute();

  @internal
  void updatePublishingLayers(List<lk_rtc.SubscribedQuality> layers) async {
    //
    logger.fine('Update publishing layers: $layers');

    final params = track?.sender?.parameters;
    if (params == null) {
      logger.fine('Update publishing layers: sender params are null');
      return;
    }

    final encodings = params.encodings;
    if (encodings == null) {
      logger.fine('Update publishing layers: encodings are null');
      return;
    }

    bool didChange = false;

    for (final encoding in encodings) {
      logger.fine('Processing encoding: ${encoding.rid}...');
      final layer = layers.firstWhereOrNull((e) =>
          // If there is exact match, use it
          (e.quality.toRid() == encoding.rid) ||
          // Use low layer if rid is null (not simulcast)
          (encoding.rid == null && e.quality == lk_models.VideoQuality.LOW));
      if (layer != null && encoding.active != layer.enabled) {
        encoding.active = layer.enabled;
        logger.fine('Setting layer ${layer.quality} to ${layer.enabled}');
        // FireFox does not support setting encoding.active to false, so we
        // have a workaround of lowering its bitrate and resolution to the min.
        // TODO: Workaround for firefox
        didChange = true;
      }
    }

    if (didChange) {
      params.encodings = encodings;
      final result = await track?.sender?.setParameters(params);
      if (result == false) {
        logger.warning('Failed to update sender parameters');
      }
    } else {
      logger.fine('Update publishing layers: nothing to change');
    }
  }

  lk_rtc.TrackPublishedResponse toPBTrackPublishedResponse() =>
      lk_rtc.TrackPublishedResponse(
        cid: track?.mediaStreamTrack.id,
        track: latestInfo,
      );
}
