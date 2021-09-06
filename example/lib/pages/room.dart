import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:livekit_example/widgets/controls.dart';
import 'package:livekit_example/widgets/video.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;

class RoomPage extends StatefulWidget {
  //
  final Room room;

  const RoomPage(
    this.room, {
    Key? key,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _RoomPageState();
  }
}

class _RoomPageState extends State<RoomPage> with RoomDelegate {
  // BuildContext? _lastContext;
  //
  List<Participant> participants = [];

  @override
  void initState() {
    super.initState();
    widget.room.delegate = this;
    widget.room.addListener(_onChange);
    _onConnected();
  }

  @override
  void dispose() {
    widget.room.delegate = null;
    widget.room.removeListener(_onChange);
    super.dispose();
  }

  void _onConnected() async {
    // video will fail when running in ios simulator
    try {
      final localVideo = await LocalVideoTrack.create(); // Defaults to camera
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
  void onDisconnected() {
    // final context = _lastContext;
    print('disconnected: $context');
    // if (context != null) {
    Navigator.pop(context);
    // }
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
                  child:
                      participants.isNotEmpty ? ParticipantView(participants.first) : Container()),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: math.max(0, participants.length - 1),
                  itemBuilder: (BuildContext context, int index) => Container(
                    width: 100,
                    height: 100,
                    padding: const EdgeInsets.all(2),
                    child: ParticipantView(participants[index + 1], quality: VideoQuality.LOW),
                  ),
                ),
              ),
              SafeArea(
                top: false,
                child: Controls(widget.room),
              ),
            ],
          ),
        ),
      );
}
