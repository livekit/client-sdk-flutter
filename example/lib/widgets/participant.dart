import 'package:collection/collection.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:livekit_example/theme.dart';

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
  TrackPublication? firstVideoPub;
  TrackPublication? firstAudioPub;

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
    setState(() {
      // For simplification, We are assuming here
      // there is only 1 video / audio tracks.
      firstAudioPub = widget.participant.audioTracks.firstOrNull;
      firstVideoPub = widget.participant.videoTracks.firstOrNull;
      if (firstVideoPub is RemoteTrackPublication) {
        (firstVideoPub as RemoteTrackPublication).videoQuality = widget.quality;
      }
    });
  }

  @override
  Widget build(BuildContext ctx) => Container(
        foregroundDecoration: BoxDecoration(
          border: widget.participant.isSpeaking
              ? Border.all(
                  width: 5,
                  color: LKColors.lkBlue,
                )
              : null,
        ),
        decoration: BoxDecoration(
          color: Theme.of(ctx).cardColor,
        ),
        child: Stack(
          children: [
            // Video
            if (firstVideoPub?.subscribed == true &&
                firstVideoPub?.muted == false)
              VideoTrackRenderer(
                firstVideoPub!.track as VideoTrack,
                fit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
              )
            else
              const NoVideoWidget(),

            Align(
              alignment: Alignment.bottomCenter,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  //
                  // Menu for Video RemoteTrackPublication
                  //
                  Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (firstVideoPub is RemoteTrackPublication)
                        RemoteTrackPublicationMenuWidget(
                          pub: firstVideoPub as RemoteTrackPublication,
                          icon: EvaIcons.videoOutline,
                        ),
                      //
                      // Menu for Audio RemoteTrackPublication
                      //
                      if (firstAudioPub is RemoteTrackPublication)
                        RemoteTrackPublicationMenuWidget(
                          pub: firstAudioPub as RemoteTrackPublication,
                          icon: EvaIcons.volumeUpOutline,
                        ),
                    ],
                  ),

                  ParticipantInfoWidget(
                    title: widget.participant.identity,
                    audioAvailable: firstAudioPub?.muted == false &&
                        firstAudioPub?.subscribed == true,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class RemoteTrackPublicationMenuWidget extends StatelessWidget {
  final IconData icon;
  final RemoteTrackPublication pub;
  const RemoteTrackPublicationMenuWidget({
    required this.pub,
    required this.icon,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => Material(
        // type: MaterialType.card,
        color: Colors.black.withOpacity(0.3),
        // shape: CircleBorder(),
        child: PopupMenuButton<Function>(
          // shape: CircleBorder(),
          icon: Icon(icon),
          onSelected: (value) => value(),
          itemBuilder: (BuildContext context) {
            return <PopupMenuEntry<Function>>[
              //
              // Subscribe/Unsubscribe
              //
              if (pub.subscribed == false)
                PopupMenuItem(
                  child: const Text('Subscribe'),
                  value: () => pub.subscribed = true,
                ),
              if (pub.subscribed == true)
                PopupMenuItem(
                  child: const Text('Un-subscribe'),
                  value: () => pub.subscribed = false,
                ),
            ];
          },
        ),
      );
}
