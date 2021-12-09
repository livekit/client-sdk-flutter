import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';

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
  late final EventsListener<RoomEvent> _listener = widget.room.createListener();

  @override
  void initState() {
    super.initState();
    widget.room.addListener(_onRoomDidUpdate);
    _setUpListeners();
    _sortParticipants();
    WidgetsBinding.instance?.addPostFrameCallback((_) => _askPublish());
  }

  @override
  void dispose() {
    // always dispose listener
    (() async {
      widget.room.removeListener(_onRoomDidUpdate);
      await _listener.dispose();
      await widget.room.dispose();
    })();
    super.dispose();
  }

  void _setUpListeners() => _listener
    ..on<RoomDisconnectedEvent>((_) async {
      WidgetsBinding.instance
          ?.addPostFrameCallback((timeStamp) => Navigator.pop(context));
    })
    ..on<DataReceivedEvent>((event) {
      String decoded = 'Failed to decode';
      try {
        decoded = utf8.decode(event.data);
      } catch (_) {
        print('Failed to decode: $_');
      }
      context.showDataReceivedDialog(decoded);
    });

  void _askPublish() async {
    final result = await context.showPublishDialog();
    if (result != true) return;
    // video will fail when running in ios simulator
    try {
      await widget.room.localParticipant?.setCameraEnabled(true);
    } catch (error) {
      print('could not publish video: $error');
      await context.showErrorDialog(error);
    }
    try {
      await widget.room.localParticipant?.setMicrophoneEnabled(true);
    } catch (error) {
      print('could not publish audio: $error');
      await context.showErrorDialog(error);
    }
  }

  void _onRoomDidUpdate() {
    _sortParticipants();
  }

  void _sortParticipants() {
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
      return a.joinedAt.millisecondsSinceEpoch -
          b.joinedAt.millisecondsSinceEpoch;
    });

    final localParticipant = widget.room.localParticipant;
    if (localParticipant != null) {
      if (participants.length > 1) {
        participants.insert(1, localParticipant);
      } else {
        participants.add(localParticipant);
      }
    }
    setState(() {
      this.participants = participants;
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Column(
          children: [
            Expanded(
                child: participants.isNotEmpty
                    ? ParticipantWidget.widgetFor(participants.first)
                    : Container()),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: math.max(0, participants.length - 1),
                itemBuilder: (BuildContext context, int index) => SizedBox(
                  width: 100,
                  height: 100,
                  child: ParticipantWidget.widgetFor(participants[index + 1]),
                ),
              ),
            ),
            if (widget.room.localParticipant != null)
              SafeArea(
                top: false,
                child:
                    ControlsWidget(widget.room, widget.room.localParticipant!),
              ),
          ],
        ),
      );
}
