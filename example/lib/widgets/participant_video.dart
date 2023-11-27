import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:livekit_example/widgets/no_video.dart';
import 'package:fluttertoast/fluttertoast.dart';

extension ParticipantExtension on Participant {
  bool get isLocalParticipant => this is LocalParticipant;
  bool get isRemoteParticipant => this is RemoteParticipant;
}

class ParticipantVideo extends StatefulWidget {
  final Participant participant;
  final Map<String, bool> participantSubscriptions;
  const ParticipantVideo(
    this.participant,
    this.participantSubscriptions, {
    Key? key,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ParticipantVideo();
}

class _ParticipantVideo extends State<ParticipantVideo> {
  String get name => isLocalParticipant
      ? '${widget.participant.name} (you)'
      : widget.participant.name;

  bool get isLocalParticipant => widget.participant.isLocalParticipant;

  @override
  Widget build(BuildContext context) {
    bool hasVideo = false;

    if (!isLocalParticipant) {
      hasVideo =
          (widget.participantSubscriptions[widget.participant.identity] ??
                  false) &&
              widget.participant.isCameraEnabled() &&
              widget.participant.videoTracks.isNotEmpty &&
              widget.participant.videoTracks[0].track != null;
    } else if (isLocalParticipant &&
        widget.participant.isCameraEnabled() &&
        widget.participant.videoTracks.isNotEmpty) {
      hasVideo = true;
    }

    return Stack(
      children: [
        if (hasVideo)
          ClipRRect(
            //borderRadius: BorderRadius.circular(AppSpacing.radiixSmall),
            child: Stack(
              children: [
                // Your video renderer
                DecoratedBox(
                  decoration: BoxDecoration(
                      //borderRadius: BorderRadius.circular(AppSpacing.radiixSmall),
                      border: Border.all(
                    color: Colors.white,
                    width: 2,
                  )),
                  position: DecorationPosition.foreground,
                  child: widget.participant.isCameraEnabled()
                      ? VideoTrackRenderer(
                          widget.participant.videoTracks[0].track as VideoTrack,
                        )
                      : const NoVideoWidget(),
                ),
                Text(
                    'cam: ${widget.participant.isCameraEnabled()}\n ${widget.participant.identity} ($name)'),
                Material(
                  type: MaterialType.transparency,
                  child: InkWell(
                    splashColor: Colors.blueGrey,
                    onTap: () {
                      Fluttertoast.showToast(
                          msg:
                              'participant.isCameraEnabled() = ${widget.participant.isCameraEnabled()}',
                          toastLength: Toast.LENGTH_SHORT,
                          gravity: ToastGravity.BOTTOM,
                          timeInSecForIosWeb: 1,
                          backgroundColor: Colors.orange,
                          textColor: Colors.white,
                          fontSize: 16.0);
                    },
                    child: Container(
                      width: double.infinity,
                      height: double.infinity,
                      color: const Color.fromARGB(0, 0, 0, 0),
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          const NoVideoWidget(),
      ],
    );
  }
}
