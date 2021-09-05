import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:collection/collection.dart';

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
  State<StatefulWidget> createState() => _ControlsState();
}

class _ControlsState extends State<Controls> {
  //
  // CameraPosition position = CameraPosition.front;

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
      final audioTrack = await LocalAudioTrack.create();
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
      final videoTrack = await LocalVideoTrack.create();
      await participant.publishVideoTrack(videoTrack);
    }
  }

  void _toggleCamera() async {
    //
    // if (this.position == position) return;

    //  track;
    // if (pub?.track is LocalVideoTrack) {
    //   track = pub!.track as LocalVideoTrack;
    // }
    final track = participant.videoTracks.values.firstOrNull?.track as LocalVideoTrack?;
//
    if (track == null) return;

    try {
      final options = track.currentOptions.copyWith(
        type: LocalVideoTrackType.camera, // Make sure it's camera
        cameraPosition: track.currentOptions.cameraPosition.swap,
      );

      await track.restartTrack(options);
    } catch (error) {
      print('could not restart track: $error');
      return;
    }

    setState(() {
      // this.position = position;
    });
  }

  void _shareScreen() async {
    //

    final track = participant.videoTracks.values.firstOrNull?.track as LocalVideoTrack?;
    if (track == null) return;

    try {
      final options = track.currentOptions.copyWith(
        type: LocalVideoTrackType.display, // Make sure it's display
        params: VideoParameters.presetFHD169,
      );

      await track.restartTrack(options);
      //
    } catch (error) {
      print('could not restart track: $error');
      return;
    }

    setState(() {
      // this.position = position;
    });
  }

  void _exit() {
    widget.room.disconnect();
  }

  @override
  Widget build(BuildContext context) {
    // mute audio
    final canMute = participant.hasAudio && !participant.isMuted;

    // mute video
    // TrackPublication? videoPub;
    // if (participant.hasVideo) {
    final videoPub = participant.videoTracks.values.firstOrNull;
    // }

    final videoEnabled = videoPub != null && !videoPub.muted;

    // if (position == CameraPosition.front) {

    // } else {
    //   buttons.add(IconButton(
    //     icon: const Icon(Icons.video_camera_back_rounded),
    //     onPressed: videoEnabled
    //         ? () {
    //             _setCameraPosition(videoPub, CameraPosition.front);
    //           }
    //         : null,
    //   ));
    // }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        //

        if (canMute)
          IconButton(
            onPressed: _muteAudio,
            icon: const Icon(Icons.mic_rounded),
          )
        else
          IconButton(
            onPressed: _unmuteAudio,
            icon: const Icon(Icons.mic_off_rounded),
          ),

        if (videoEnabled)
          IconButton(
            onPressed: _muteVideo,
            icon: const Icon(Icons.videocam_rounded),
          )
        else
          IconButton(
            onPressed: _unmuteVideo,
            icon: const Icon(Icons.videocam_off_rounded),
          ),

        IconButton(
          icon: const Icon(Icons.video_camera_front_rounded),
          onPressed: () => _toggleCamera(),
        ),

        IconButton(
          icon: const Icon(Icons.star),
          onPressed: () => _shareScreen(),
        ),

        IconButton(
          onPressed: _exit,
          icon: const Icon(Icons.close_rounded),
        )
      ],
    );
  }
}
