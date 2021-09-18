import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:provider/provider.dart';

import '../exts.dart';
import '../widgets/controls.dart';
import '../widgets/participant.dart';

class RoomPage extends StatefulWidget {
  //
  final Room room;

  const RoomPage(
    this.room, {
    Key? key,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _RoomPageState();
}

class _RoomPageState extends State<RoomPage> {
  //
  List<Participant> participants = [];
  late final _listener = EventsListener(widget.room.events);

  @override
  void initState() {
    super.initState();
    widget.room.addListener(_onChange);
    _onConnected();
    _setUpListeners();
  }

  @override
  void dispose() async {
    await _listener.dispose();
    widget.room.removeListener(_onChange);
    super.dispose();
  }

  void _setUpListeners() => _listener
    ..on<RoomDisconnectedEvent>((_) => Navigator.pop(context))
    ..on<RoomDataReceivedEvent>((event) => context.showDataReceivedDialog(utf8.decode(event.data)));

  void _onConnected() async {
    // video will fail when running in ios simulator
    try {
      final localVideo = await LocalVideoTrack.createCameraTrack(); // Defaults to camera
      await widget.room.localParticipant.publishVideoTrack(
        localVideo,
        // options: TrackPublishOptions(
        //   //   simulcast: true,
        //   videoEncoding: VideoParameters.presetQVGA169.encoding,
        // ),
      );
    } catch (e) {
      print('could not publish video: $e');
    }

    final localAudio = await LocalAudioTrack.create();
    await widget.room.localParticipant.publishAudioTrack(localAudio);
    sortParticipants();
  }

  void _onChange() {
    sortParticipants();
  }

  void sortParticipants() {
    List<Participant> participants = [];
    participants.addAll(widget.room.participants.values);
    // sort speakers for the grid
    participants.sort((a, b) {
      // loudest speaker first
      if (a.isSpeaking && b.isSpeaking) {
        if (a.audioLevel > b.audioLevel) {
          return -1;
        } else {
          return 1;
        }
      }

      // last spoken at
      final aSpokeAt = a.lastSpokeAt?.millisecondsSinceEpoch ?? 0;
      final bSpokeAt = b.lastSpokeAt?.millisecondsSinceEpoch ?? 0;

      if (aSpokeAt != bSpokeAt) {
        return aSpokeAt > bSpokeAt ? -1 : 1;
      }

      // video on
      if (a.hasVideo != b.hasVideo) {
        return a.hasVideo ? -1 : 1;
      }

      // joinedAt
      return a.joinedAt.millisecondsSinceEpoch - b.joinedAt.millisecondsSinceEpoch;
    });

    if (participants.length > 1) {
      participants.insert(1, widget.room.localParticipant);
    } else {
      participants.add(widget.room.localParticipant);
    }
    setState(() {
      this.participants = participants;
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        // with a provider, any child/descendent widget can be updated if they
        // are a Consumer of Room.
        body: ChangeNotifierProvider.value(
          value: widget.room,
          child: Column(
            children: [
              Expanded(
                  child: participants.isNotEmpty
                      ? ParticipantWidget(participants.first)
                      : Container()),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: math.max(0, participants.length - 1),
                  itemBuilder: (BuildContext context, int index) => Container(
                    width: 100,
                    height: 100,
                    padding: const EdgeInsets.all(2),
                    child: ParticipantWidget(participants[index + 1], quality: VideoQuality.LOW),
                  ),
                ),
              ),
              SafeArea(
                top: false,
                child: ControlsWidget(widget.room),
              ),
            ],
          ),
        ),
      );
}
