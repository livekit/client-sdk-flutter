import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';

import 'participant.dart';

extension ParticipantExtension on Participant {
  bool get isLocalParticipant => this is LocalParticipant;
  bool get isRemoteParticipant => this is RemoteParticipant;
}

class ParticipantGridTile extends StatefulWidget {
  final Participant participant;
  final Map<String, bool> participantSubscriptions;
  const ParticipantGridTile(
    this.participant,
    this.participantSubscriptions, {
    Key? key,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ParticipantGridTile();
}

class _ParticipantGridTile extends State<ParticipantGridTile> {
  String get name => isLocalParticipant
      ? '${widget.participant.name} (you)'
      : widget.participant.name;

  bool get isLocalParticipant => widget.participant.isLocalParticipant;

  @override
  Widget build(BuildContext context) {
    /*
    bool hasVideo = false;

    if (!isLocalParticipant) {
      hasVideo =
          (widget.participantSubscriptions[widget.participant.identity] ??
                  false) &&
              widget.participant.isCameraEnabled() &&
              widget.participant.videoTrackPublications.isNotEmpty &&
              widget.participant.videoTrackPublications[0].track != null;
    } else if (isLocalParticipant &&
        widget.participant.isCameraEnabled() &&
        widget.participant.videoTrackPublications.isNotEmpty) {
      hasVideo = true;
    }
    */
    return Stack(
      children: [
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
                child: ParticipantWidget.widgetFor(widget.participant),
              ),
              /*Material(
                type: MaterialType.transparency,
                child: InkWell(
                  splashColor: Colors.blueGrey,
                  onTap: () {
                    if (lkPlatformIsMobile()) {
                      Fluttertoast.showToast(
                          msg:
                              'participant.isCameraEnabled() = ${widget.participant.isCameraEnabled()}, hasVideo = $hasVideo',
                          toastLength: Toast.LENGTH_SHORT,
                          gravity: ToastGravity.BOTTOM,
                          timeInSecForIosWeb: 1,
                          backgroundColor: Colors.orange,
                          textColor: Colors.white,
                          fontSize: 16.0);
                    } else {
                      print(
                          'participant.isCameraEnabled() = ${widget.participant.isCameraEnabled()}, hasVideo = $hasVideo');
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: const Color.fromARGB(0, 0, 0, 0),
                  ),
                ),
              ),*/
            ],
          ),
        )
      ],
    );
  }
}
