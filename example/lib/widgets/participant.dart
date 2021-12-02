import 'package:collection/collection.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:livekit_example/theme.dart';

import 'no_video.dart';
import 'participant_info.dart';

abstract class ParticipantWidget extends StatefulWidget {
  // Convenience method to return relevant widget for participant
  static ParticipantWidget widgetFor(Participant participant) {
    if (participant is LocalParticipant) {
      return LocalParticipantWidget(participant);
    } else if (participant is RemoteParticipant) {
      return RemoteParticipantWidget(participant);
    }
    throw UnimplementedError('Unknown participant type');
  }

  // Must be implemented by child class
  abstract final Participant participant;
  final VideoQuality quality;

  const ParticipantWidget({
    this.quality = VideoQuality.MEDIUM,
    Key? key,
  }) : super(key: key);
}

class LocalParticipantWidget extends ParticipantWidget {
  @override
  final LocalParticipant participant;

  const LocalParticipantWidget(
    this.participant, {
    Key? key,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _LocalParticipantWidgetState();
}

class RemoteParticipantWidget extends ParticipantWidget {
  @override
  final RemoteParticipant participant;

  const RemoteParticipantWidget(
    this.participant, {
    Key? key,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _RemoteParticipantWidgetState();
}

abstract class _ParticipantWidgetState<T extends ParticipantWidget>
    extends State<T> {
  //
  bool _visible = true;
  VideoTrack? get activeVideoTrack;
  TrackPublication? get firstVideoPublication;
  TrackPublication? get firstAudioPublication;

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
  void didUpdateWidget(covariant T oldWidget) {
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
      // firstAudioPub = widget.participant.audioTracks.firstOrNull;
      // firstVideoPub = widget.participant.videoTracks.firstOrNull;
      // if (firstVideoPub is RemoteTrackPublication) {
      //   (firstVideoPub as RemoteTrackPublication).videoQuality = widget.quality;
      // }
    });
  }

  // Widgets to stack above
  List<Widget> above() => [];

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
            InkWell(
              onTap: () => setState(() => _visible = !_visible),
              child: activeVideoTrack != null
                  ? VideoTrackRenderer(
                      activeVideoTrack!,
                      fit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                    )
                  : const NoVideoWidget(),
            ),

            // Bottom bar
            Align(
              alignment: Alignment.bottomCenter,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...above(),
                  ParticipantInfoWidget(
                    title: widget.participant.identity,
                    audioAvailable: firstAudioPublication?.muted == false &&
                        firstAudioPublication?.subscribed == true,
                    connectionQuality: widget.participant.connectionQuality,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _LocalParticipantWidgetState
    extends _ParticipantWidgetState<LocalParticipantWidget> {
  @override
  LocalTrackPublication<LocalVideoTrack>? get firstVideoPublication =>
      widget.participant.videoTracks.firstOrNull;

  @override
  LocalTrackPublication<LocalAudioTrack>? get firstAudioPublication =>
      widget.participant.audioTracks.firstOrNull;

  @override
  VideoTrack? get activeVideoTrack {
    if (firstVideoPublication?.subscribed == true &&
        firstVideoPublication?.muted == false &&
        _visible) {
      return firstVideoPublication?.track;
    }
  }
}

class _RemoteParticipantWidgetState
    extends _ParticipantWidgetState<RemoteParticipantWidget> {
  @override
  RemoteTrackPublication<RemoteVideoTrack>? get firstVideoPublication =>
      widget.participant.videoTracks.firstOrNull;

  @override
  RemoteTrackPublication<RemoteAudioTrack>? get firstAudioPublication =>
      widget.participant.audioTracks.firstOrNull;

  @override
  VideoTrack? get activeVideoTrack {
    if (firstVideoPublication?.subscribed == true &&
        firstVideoPublication?.muted == false &&
        _visible) {
      return firstVideoPublication?.track;
    }
  }

  @override
  List<Widget> above() => [
        Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (firstVideoPublication != null)
              RemoteTrackPublicationMenuWidget(
                pub: firstVideoPublication!,
                icon: EvaIcons.videoOutline,
              ),
            // Menu for Audio RemoteTrackPublication
            if (firstAudioPublication != null)
              RemoteTrackPublicationMenuWidget(
                pub: firstAudioPublication!,
                icon: EvaIcons.volumeUpOutline,
              ),
          ],
        ),
      ];
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
