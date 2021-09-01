import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';

class Controls extends StatefulWidget {
  //
  final Room room;
  final LocalParticipant participant;

  Controls(
    this.room, {
    Key? key,
  })  : participant = room.localParticipant,
        super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _ControlsState();
  }
}

class _ControlsState extends State<Controls> {
  CameraPosition position = CameraPosition.front;

  @override
  void initState() {
    super.initState();
    participant.addListener(_onChange);
  }

  @override
  void dispose() {
    participant.removeListener(_onChange);
    super.dispose();
  }

  LocalParticipant get participant => widget.participant;

  void _onChange() {
    // trigger refresh
    setState(() {});
  }

  void _muteAudio() {
    if (participant.hasAudio) {
      final audioPub = participant.audioTracks.values.first;
      audioPub.muted = true;
    }
  }

  Future<void> _unmuteAudio() async {
    if (participant.hasAudio) {
      final audioPub = participant.audioTracks.values.first;
      audioPub.muted = false;
    } else {
      // publish audio track
      final audioTrack = await LocalAudioTrack.createTrack();
      await participant.publishAudioTrack(audioTrack);
    }
  }

  void _muteVideo() {
    if (participant.hasVideo) {
      final videoPub = participant.videoTracks.values.first;
      videoPub.muted = true;
    }
  }

  void _unmuteVideo() async {
    if (participant.hasVideo) {
      final videoPub = participant.videoTracks.values.first;
      videoPub.muted = false;
    } else {
      // publish audio track
      final videoTrack = await LocalVideoTrack.createCameraTrack();
      await participant.publishVideoTrack(videoTrack);
    }
  }

  void _setCameraPosition(TrackPublication? pub, CameraPosition position) async {
    if (this.position == position) {
      return;
    }
    LocalVideoTrack? track;
    if (pub?.track is LocalVideoTrack) {
      track = pub!.track as LocalVideoTrack;
    }

    if (track == null) {
      return;
    }

    try {
      await track.restartTrack(options: LocalVideoTrackOptions(position: position));
    } catch (e) {
      print('could not restart track: $e');
      return;
    }

    setState(() {
      this.position = position;
    });
  }

  void _exit() {
    widget.room.disconnect();
  }

  @override
  Widget build(BuildContext context) {
    final buttons = <Widget>[];

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

    final videoEnabled = videoPub != null && !videoPub.muted;
    if (videoEnabled) {
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

    if (position == CameraPosition.front) {
      buttons.add(IconButton(
        icon: const Icon(Icons.video_camera_front_rounded),
        onPressed: videoEnabled
            ? () {
                _setCameraPosition(videoPub, CameraPosition.back);
              }
            : null,
      ));
    } else {
      buttons.add(IconButton(
        icon: const Icon(Icons.video_camera_back_rounded),
        onPressed: videoEnabled
            ? () {
                _setCameraPosition(videoPub, CameraPosition.front);
              }
            : null,
      ));
    }

    buttons.add(IconButton(
      onPressed: _exit,
      icon: const Icon(Icons.close_rounded),
    ));

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: buttons,
    );
  }
}
