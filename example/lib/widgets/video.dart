//
//
//

// displays a participant in view
import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class VideoView extends StatefulWidget {
  //
  final Participant participant;
  final VideoQuality quality;

  const VideoView(
    this.participant, {
    this.quality = VideoQuality.MEDIUM,
    Key? key,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _VideoViewState();
}

class _VideoViewState extends State<VideoView> with ParticipantDelegate {
  //
  TrackPublication? videoPub;

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
  void didUpdateWidget(covariant VideoView oldWidget) {
    oldWidget.participant.removeListener(_onParticipantChanged);
    widget.participant.addListener(_onParticipantChanged);
    _onParticipantChanged();
    super.didUpdateWidget(oldWidget);
  }

  // register for change so Flutter will re-build the widget upon change
  void _onParticipantChanged() {
    final subscribedVideos = widget.participant.videoTracks.values.where((pub) {
      return pub.kind == TrackType.VIDEO && !pub.isScreenShare && pub.subscribed;
    });
    setState(() {
      if (subscribedVideos.isNotEmpty) {
        final videoPub = subscribedVideos.first;
        if (videoPub is RemoteTrackPublication) {
          videoPub.videoQuality = widget.quality;
        }
        // when muted, show placeholder
        if (!videoPub.muted) {
          this.videoPub = videoPub;
          return;
        }
      }
      videoPub = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final videoPub = this.videoPub;
    if (videoPub == null) {
      return Container(
        color: Colors.grey,
      );
    }

    return VideoTrackRenderer(
      videoPub.track as VideoTrack,
      fit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
    );
  }
}
