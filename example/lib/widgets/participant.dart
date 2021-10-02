import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:livekit_client/livekit_client.dart';

import 'no_video.dart';
import 'participant_info.dart';

class ParticipantWidget extends StatefulWidget {
  //
  final Participant participant;
  final VideoQuality quality;

  const ParticipantWidget(
    this.participant, {
    this.quality = VideoQuality.MEDIUM,
    Key? key,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ParticipantWidgetState();
}

class _ParticipantWidgetState extends State<ParticipantWidget> {
  //
  TrackPublication? videoPub;
  TrackPublication? audioPub;

  @override
  void initState() {
    super.initState();
    widget.participant.addListener(_onParticipantChanged);
    _onParticipantChanged();
  }

  @override
  void dispose() {
    widget.participant.removeListener(_onParticipantChanged);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ParticipantWidget oldWidget) {
    oldWidget.participant.removeListener(_onParticipantChanged);
    widget.participant.addListener(_onParticipantChanged);
    _onParticipantChanged();
    super.didUpdateWidget(oldWidget);
  }

  // register for change so Flutter will re-build the widget upon change
  void _onParticipantChanged() {
    //
    final firstAudio = widget.participant.audioTracks
        .firstWhereOrNull((pub) => pub.subscribed);
    final firstVideo = widget.participant.videoTracks
        .firstWhereOrNull((pub) => !pub.isScreenShare && pub.subscribed);

    if (firstVideo is RemoteTrackPublication) {
      firstVideo.videoQuality = widget.quality;
    }

    setState(() {
      audioPub = !(firstAudio?.muted ?? true) ? firstAudio : null;
      videoPub = !(firstVideo?.muted ?? true) ? firstVideo : null;
    });
  }

  @override
  Widget build(BuildContext ctx) => Container(
        color: Theme.of(ctx).cardColor,
        child: Stack(
          children: [
            // Video
            if (videoPub != null)
              VideoTrackRenderer(
                videoPub!.track as VideoTrack,
                fit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
              )
            else
              const NoVideoWidget(),

            Align(
              alignment: Alignment.bottomCenter,
              child: ParticipantInfoWidget(
                title: widget.participant.identity,
                muted: audioPub == null,
              ),
            ),
          ],
        ),
      );
}
