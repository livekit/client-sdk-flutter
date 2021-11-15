import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background/flutter_background.dart';
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
    if (result == true) await participant.unpublishAllTracks();
  }

  void _muteAudio() async {
    await participant.setMicrophoneEnabled(false);
    // The following code is an example how to mute a track
    // if (participant.hasAudio) {
    // final audioPub = participant.audioTracks.first;
    // audioPub.muted = true;
    // }
  }

  Future<void> _unmuteAudio() async {
    await participant.setMicrophoneEnabled(true);
    // The following code is an example how to unmute / publish a audio track
    // if (participant.hasAudio) {
    //   final audioPub = participant.audioTracks.first;
    //   audioPub.muted = false;
    // } else {
    //   // publish audio track
    //   final audioTrack = await LocalAudioTrack.create();
    //   await participant.publishAudioTrack(audioTrack);
    // }
  }

  void _muteVideo() async {
    await participant.setCameraEnabled(false);
    // The following code is an example how to mute a video track
    // if (participant.hasVideo) {
    //   final videoPub = participant.videoTracks.first;
    //   videoPub.muted = true;
    // }
  }

  void _unmuteVideo() async {
    await participant.setCameraEnabled(true);
    // The following code is an example how to unmute / publish a video track
    // if (participant.hasVideo) {
    //   print('Un-muting video');
    //   final videoPub = participant.videoTracks.first;
    //   videoPub.muted = false;
    // } else {
    //   // publish audio track
    //   final videoTrack = await LocalVideoTrack.createCameraTrack();
    //   await participant.publishVideoTrack(videoTrack);
    // }
  }

  void _toggleCamera() async {
    //
    final track =
        participant.videoTracks.firstOrNull?.track as LocalVideoTrack?;
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
    final lp = widget.room.localParticipant;

    for (final track in lp.videoTracks) {
      await lp.unpublishTrack(track.sid);
    }

    try {
      // Required for android screenshare.
      const androidConfig = FlutterBackgroundAndroidConfig(
        notificationTitle: 'Screen Sharing',
        notificationText: 'LiveKit Example is sharing the screen.',
        notificationImportance: AndroidNotificationImportance.Default,
        notificationIcon:
            AndroidResource(name: 'livekit_ic_launcher', defType: 'mipmap'),
      );
      await FlutterBackground.initialize(androidConfig: androidConfig);
      await FlutterBackground.enableBackgroundExecution();

      final screenTrack =
          await LocalVideoTrack.createScreenTrack(); // Defaults to camera
      await widget.room.localParticipant.publishVideoTrack(
        screenTrack,
      );
    } catch (e) {
      print('could not publish video: $e');
    }
  }

  void _unshareScreen() async {
    final lp = widget.room.localParticipant;

    try {
      await lp.setScreenShareEnabled(false);
      await FlutterBackground.disableBackgroundExecution();
    } catch (e) {
      print('error disabling screen share: $e');
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

    final videoPub =
        participant.getTrackPublicationBySource(TrackSource.camera);
    final videoEnabled = videoPub != null && !videoPub.muted;
    final screenSharePub =
        participant.getTrackPublicationBySource(TrackSource.screenShareVideo);
    final screenShareEnabled = screenSharePub != null && !screenSharePub.muted;

    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 15,
        horizontal: 15,
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 5,
        runSpacing: 5,
        children: [
          IconButton(
            onPressed: _unpublishAll,
            icon: const Icon(EvaIcons.closeCircleOutline),
            tooltip: 'Unpublish all',
          ),
          if (canMute)
            IconButton(
              onPressed: _muteAudio,
              icon: const Icon(EvaIcons.mic),
              tooltip: 'mute audio',
            )
          else
            IconButton(
              onPressed: _unmuteAudio,
              icon: const Icon(EvaIcons.micOff),
              tooltip: 'un-mute audio',
            ),
          if (videoEnabled)
            IconButton(
              onPressed: _muteVideo,
              icon: const Icon(EvaIcons.video),
              tooltip: 'mute video',
            )
          else
            IconButton(
              onPressed: _unmuteVideo,
              icon: const Icon(EvaIcons.videoOff),
              tooltip: 'un-mute video',
            ),
          IconButton(
            icon: Icon(position == CameraPosition.back
                ? EvaIcons.camera
                : EvaIcons.person),
            onPressed: () => _toggleCamera(),
            tooltip: 'toggle camera',
          ),
          if (screenShareEnabled)
            IconButton(
              icon: const Icon(EvaIcons.monitorOutline),
              onPressed: () => _unshareScreen(),
              tooltip: 'unshare screen (experimental)',
            )
          else
            IconButton(
              icon: const Icon(EvaIcons.monitor),
              onPressed: () => _shareScreen(),
              tooltip: 'share screen (experimental)',
            ),
          IconButton(
            onPressed: _onTapDisconnect,
            icon: const Icon(EvaIcons.closeCircle),
            tooltip: 'disconnect',
          ),
          IconButton(
            onPressed: _onTapSendData,
            icon: const Icon(EvaIcons.paperPlane),
            tooltip: 'send demo data',
          ),
          IconButton(
            onPressed: _onTapReconnect,
            icon: const Icon(EvaIcons.refresh),
            tooltip: 're-connect',
          ),
        ],
      ),
    );
  }
}
