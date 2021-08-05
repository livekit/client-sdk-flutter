import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';

class Controls extends StatefulWidget {
  final Room room;
  final LocalParticipant participant;

  Controls(this.room) : participant = room.localParticipant;

  @override
  State<StatefulWidget> createState() {
    return _ControlsState();
  }
}

class _ControlsState extends State<Controls> {
  @override
  void initState() {
    super.initState();
    widget.participant.addListener(_onChange);
  }

  @override
  void dispose() {
    widget.participant.removeListener(_onChange);
    super.dispose();
  }

  LocalParticipant get participant => widget.participant;

  _onChange() {
    // trigger refresh
    setState(() {});
  }

  _muteAudio() {
    if (participant.hasAudio) {
      var audioPub = participant.audioTracks.values.first;
      audioPub.muted = true;
    }
  }

  _unmuteAudio() async {
    if (participant.hasAudio) {
      var audioPub = participant.audioTracks.values.first;
      audioPub.muted = false;
    } else {
      // publish audio track
      var audioTrack = await LocalAudioTrack.createTrack();
      await participant.publishAudioTrack(audioTrack);
    }
  }

  _muteVideo() {
    if (participant.hasVideo) {
      var videoPub = participant.videoTracks.values.first;
      videoPub.muted = true;
    }
  }

  _unmuteVideo() async {
    if (participant.hasVideo) {
      var videoPub = participant.videoTracks.values.first;
      videoPub.muted = false;
    } else {
      // publish audio track
      var videoTrack = await LocalVideoTrack.createCameraTrack();
      await participant.publishVideoTrack(videoTrack);
    }
  }

  _exit() {
    widget.room.disconnect();
  }

  @override
  Widget build(BuildContext context) {
    var buttons = <Widget>[];

    // mute audio
    if (participant.hasAudio && !participant.isMuted) {
      buttons.add(
        IconButton(
          onPressed: _muteAudio,
          icon: const Icon(Icons.mic_rounded),
        ),
      );
    } else {
      buttons.add(
        IconButton(
          onPressed: _unmuteAudio,
          icon: const Icon(Icons.mic_off_rounded),
        ),
      );
    }

    // mute video
    TrackPublication? videoPub;
    if (participant.hasVideo) {
      videoPub = participant.videoTracks.values.first;
    }

    if (videoPub != null && videoPub.muted) {
      buttons.add(IconButton(
        onPressed: _muteVideo,
        icon: const Icon(Icons.videocam_rounded),
      ));
    } else {
      buttons.add(IconButton(
        onPressed: _unmuteVideo,
        icon: const Icon(Icons.videocam_off_rounded),
      ));
    }

    buttons.add(IconButton(
      onPressed: _exit,
      icon: const Icon(Icons.close_rounded),
    ));

    return Row(children: buttons);
  }
}
