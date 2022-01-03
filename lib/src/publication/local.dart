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
    final params = track?.sender?.parameters;
    if (params == null) return;

    final encodings = params.encodings;
    if (encodings == null) return;

    bool didChange = false;

    for (final encoding in encodings) {
      final layer = layers.firstWhereOrNull((e) =>
          // If there is exact match, use it
          (e.quality.toRid() == encoding.rid) ||
          // Use low layer if rid is null (not simulcast)
          (encoding.rid == null && e.quality == lk_models.VideoQuality.LOW));
      if (layer != null && encoding.active != layer.enabled) {
        encoding.active = layer.enabled;
        logger.fine('Setting layer ${layer.quality} to ${layer.enabled}');
        didChange = true;
      }
    }

    if (didChange) {
      params.encodings = encodings;
      final result = await track?.sender?.setParameters(params);
      if (result == false) {
        logger.warning('Failed to update sender parameters');
      }
    }
  }
}
