//
//
//

// displays a participant in view
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'dart:math' as math;
import 'package:collection/collection.dart';

class ParticipantView extends StatefulWidget {
  //
  final Participant participant;
  final VideoQuality quality;

  const ParticipantView(
    this.participant, {
    this.quality = VideoQuality.MEDIUM,
    Key? key,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ParticipantViewState();
}

class _ParticipantViewState extends State<ParticipantView> with ParticipantDelegate {
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
  void didUpdateWidget(covariant ParticipantView oldWidget) {
    oldWidget.participant.removeListener(_onParticipantChanged);
    widget.participant.addListener(_onParticipantChanged);
    _onParticipantChanged();
    super.didUpdateWidget(oldWidget);
  }

  // register for change so Flutter will re-build the widget upon change
  void _onParticipantChanged() {
    //
    final firstAudio = widget.participant.audioTracks.firstWhereOrNull((pub) => pub.subscribed);
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
            //
            // Video
            //
            if (videoPub != null)
              VideoTrackRenderer(
                videoPub!.track as VideoTrack,
                fit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
              )
            else
              const EmptyWidget(),

            Align(
              alignment: Alignment.bottomCenter,
              child: ParticipantBarWidget(
                title: widget.participant.identity,
                muted: audioPub == null,
              ),
            ),
          ],
        ),
      );
}

class ParticipantBarWidget extends StatelessWidget {
  //
  final String? title;
  final bool muted;

  const ParticipantBarWidget({
    this.title,
    this.muted = true,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => Container(
        color: Colors.black.withOpacity(0.3),
        padding: const EdgeInsets.symmetric(
          vertical: 7,
          horizontal: 10,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (title != null)
              Flexible(
                child: Text(
                  title!,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(left: 5),
              child: Icon(
                !muted ? EvaIcons.mic : EvaIcons.micOff,
                color: !muted ? Colors.white : Colors.red,
                size: 16,
              ),
            ),
          ],
        ),
      );
}

class EmptyWidget extends StatelessWidget {
  //
  const EmptyWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => Container(
        alignment: Alignment.center,
        child: LayoutBuilder(
          builder: (ctx, constraints) => Icon(
            EvaIcons.videoOffOutline,
            color: Theme.of(ctx).accentColor,
            size: math.min(constraints.maxHeight, constraints.maxWidth) * 0.3,
          ),
        ),
      );
}
