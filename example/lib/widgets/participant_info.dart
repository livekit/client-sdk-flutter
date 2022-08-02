import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';

class ParticipantTrack {
  ParticipantTrack(
      {required this.participant,
      required this.videoTrack,
      required this.isScreenShare});
  VideoTrack? videoTrack;
  Participant participant;
  final bool isScreenShare;
}

class ParticipantInfoWidget extends StatelessWidget {
  //
  final String? title;
  final bool audioAvailable;
  final ConnectionQuality connectionQuality;
  final bool isScreenShare;

  const ParticipantInfoWidget({
    this.title,
    this.audioAvailable = true,
    this.connectionQuality = ConnectionQuality.unknown,
    this.isScreenShare = false,
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
            isScreenShare
                ? const Padding(
                    padding: EdgeInsets.only(left: 5),
                    child: Icon(
                      EvaIcons.monitor,
                      color: Colors.white,
                      size: 16,
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.only(left: 5),
                    child: Icon(
                      audioAvailable ? EvaIcons.mic : EvaIcons.micOff,
                      color: audioAvailable ? Colors.white : Colors.red,
                      size: 16,
                    ),
                  ),
            if (connectionQuality != ConnectionQuality.unknown)
              Padding(
                padding: const EdgeInsets.only(left: 5),
                child: Icon(
                  connectionQuality == ConnectionQuality.poor
                      ? EvaIcons.wifiOffOutline
                      : EvaIcons.wifi,
                  color: {
                    ConnectionQuality.excellent: Colors.green,
                    ConnectionQuality.good: Colors.orange,
                    ConnectionQuality.poor: Colors.red,
                  }[connectionQuality],
                  size: 16,
                ),
              ),
          ],
        ),
      );
}
