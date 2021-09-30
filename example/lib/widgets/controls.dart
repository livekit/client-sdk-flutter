import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';

import '../exts.dart';

class ControlsWidget extends StatefulWidget {
  //
  final Room room;
  final LocalParticipant participant;

  ControlsWidget(
    this.room, {
    Key? key,
  })  : participant = room.localParticipant,
        super(key: key);

  @override
  State<StatefulWidget> createState() => _ControlsWidgetState();
}

class _ControlsWidgetState extends State<ControlsWidget> {
  //
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

  void _unpublishAll() async {
    final result = await context.showUnPublishDialog();
    if (result == true) {
      await participant.unpublishAllTracks();
      // Force to update UI for now
      participant.notifyListeners();
    }
  }

  void _muteAudio() {
    if (participant.hasAudio) {
      final audioPub = participant.audioTracks.first;
      audioPub.muted = true;
    }
  }

  Future<void> _unmuteAudio() async {
    if (participant.hasAudio) {
      final audioPub = participant.audioTracks.first;
      audioPub.muted = false;
    } else {
      // publish audio track
      final audioTrack = await LocalAudioTrack.create();
      await participant.publishAudioTrack(audioTrack);
    }
  }

  void _muteVideo() {
    if (participant.hasVideo) {
      final videoPub = participant.videoTracks.first;
      videoPub.muted = true;
    }
  }

  void _unmuteVideo() async {
    if (participant.hasVideo) {
      print('Un-muting video');
      final videoPub = participant.videoTracks.first;
      videoPub.muted = false;
    } else {
      // publish audio track
      final videoTrack = await LocalVideoTrack.createCameraTrack();
      await participant.publishVideoTrack(videoTrack);
    }
  }

  void _toggleCamera() async {
    //
    final track = participant.videoTracks.firstOrNull?.track as LocalVideoTrack?;
    if (track == null) return;

    try {
      final newPosition = position.swap();
      await track.setCameraPosition(newPosition);
      setState(() {
        position = newPosition;
      });
    } catch (error) {
      print('could not restart track: $error');
      return;
    }
  }

  void _shareScreen() async {
    //
    final lp = widget.room.localParticipant;

    for (final track in lp.videoTracks) {
      await lp.unpublishTrack(track.sid);
    }

    try {
      final screenTrack = await LocalVideoTrack.createScreenTrack(); // Defaults to camera
      await widget.room.localParticipant.publishVideoTrack(
        screenTrack,
      );
    } catch (e) {
      print('could not publish video: $e');
    }
  }

  void _onTapDisconnect() async {
    final result = await context.showDisconnectDialog();
    if (result == true) await widget.room.disconnect();
  }

  void _onTapReconnect() async {
    final result = await context.showReconnectDialog();
    if (result == true) await widget.room.reconnect();
  }

  void _onTapSendData() async {
    final result = await context.showSendDataDialog();
    if (result == true) {
      await widget.room.localParticipant.publishData(
        utf8.encode('This is a sample data message'),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // mute audio
    final canMute = participant.hasAudio && !participant.isMuted;

    final videoPub = participant.videoTracks.firstOrNull;
    final videoEnabled = videoPub != null && !videoPub.muted;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: _unpublishAll,
          icon: const Icon(EvaIcons.closeCircleOutline),
        ),
        if (canMute)
          IconButton(
            onPressed: _muteAudio,
            icon: const Icon(EvaIcons.mic),
          )
        else
          IconButton(
            onPressed: _unmuteAudio,
            icon: const Icon(EvaIcons.micOff),
          ),
        if (videoEnabled)
          IconButton(
            onPressed: _muteVideo,
            icon: const Icon(EvaIcons.video),
          )
        else
          IconButton(
            onPressed: _unmuteVideo,
            icon: const Icon(EvaIcons.videoOff),
          ),
        IconButton(
          icon: Icon(position == CameraPosition.back ? EvaIcons.camera : EvaIcons.person),
          onPressed: () => _toggleCamera(),
        ),
        IconButton(
          icon: const Icon(EvaIcons.monitor),
          onPressed: () => _shareScreen(),
        ),
        IconButton(
          onPressed: _onTapDisconnect,
          icon: const Icon(EvaIcons.closeCircle),
        ),
        IconButton(
          onPressed: _onTapSendData,
          icon: const Icon(EvaIcons.paperPlane),
        ),
        IconButton(
          onPressed: _onTapReconnect,
          icon: const Icon(EvaIcons.refresh),
        ),
      ],
    );
  }
}
