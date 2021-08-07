import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:livekit_example/src/controls.dart';
import 'package:provider/provider.dart';

class RoomWidget extends StatefulWidget {
  final Room room;

  RoomWidget(this.room);

  @override
  State<StatefulWidget> createState() {
    return _RoomState();
  }
}

class _RoomState extends State<RoomWidget> with RoomDelegate {
  BuildContext? _lastContext;
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
    super.dispose();
  }

  _onConnected() async {
    // video will fail when running in ios simulator
    try {
      var localVideo = await LocalVideoTrack.createCameraTrack();
      await widget.room.localParticipant.publishVideoTrack(localVideo);
    } catch (e) {
      print('could not publish video: $e');
    }

    var localAudio = await LocalAudioTrack.createTrack();
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
      var aSpokeAt = a.lastSpokeAt?.millisecondsSinceEpoch;
      var bSpokeAt = b.lastSpokeAt?.millisecondsSinceEpoch;
      if (aSpokeAt == null) {
        aSpokeAt = 0;
      }
      if (bSpokeAt == null) {
        bSpokeAt = 0;
      }
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
    var context = _lastContext;
    print("disconnected: $context");
    if (context != null) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    _lastContext = context;

    var mainWidgets = <Widget>[];
    var participants = this.participants;
    if (participants.isNotEmpty) {
      mainWidgets.add(Expanded(child: VideoView(participants.first)));
    } else {
      mainWidgets.add(Expanded(child: Container()));
    }

    if (participants.length > 1) {
      var videoList = ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: participants.length - 1,
        itemBuilder: (BuildContext context, int index) {
          return Container(
            width: 100,
            height: 60,
            padding: const EdgeInsets.all(2),
            child:
                VideoView(participants[index + 1], quality: VideoQuality.LOW),
          );
        },
      );
      mainWidgets.add(Container(
        height: 60,
        child: videoList,
      ));
    }

    mainWidgets.add(Controls(widget.room));
    return MaterialApp(
        title: 'LiveKit Video Room',
        theme: ThemeData(
          primarySwatch: Colors.deepPurple,
        ),
        home: Scaffold(
            // with a provider, any child/descendent widget can be updated if they
            // are a Consumer of Room.
            body: ChangeNotifierProvider.value(
                value: widget.room,
                child: Column(
                  children: mainWidgets,
                ))));
  }
}

class VideoView extends StatefulWidget {
  final Participant participant;
  final VideoQuality quality;

  VideoView(this.participant, {VideoQuality quality = VideoQuality.MEDIUM})
      : this.quality = quality;

  @override
  State<StatefulWidget> createState() {
    return _VideoViewState();
  }
}

class _VideoViewState extends State<VideoView> with ParticipantDelegate {
  TrackPublication? videoPub;

  @override
  void initState() {
    super.initState();
    widget.participant.addListener(this._onParticipantChanged);
    _onParticipantChanged();
  }

  @override
  void dispose() {
    widget.participant.removeListener(this._onParticipantChanged);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant VideoView oldWidget) {
    oldWidget.participant.removeListener(_onParticipantChanged);
    widget.participant.addListener(_onParticipantChanged);
    _onParticipantChanged();
    super.didUpdateWidget(oldWidget);
  }

  // register for change so Flutter will re-build the widget upon change
  void _onParticipantChanged() {
    var subscribedVideos = widget.participant.videoTracks.values.where((pub) {
      return pub.kind == TrackType.VIDEO &&
          !pub.isScreenShare &&
          pub.subscribed;
    });

    setState(() {
      if (subscribedVideos.length > 0) {
        var videoPub = subscribedVideos.first;
        if (videoPub is RemoteTrackPublication) {
          videoPub.videoQuality = widget.quality;
        }
        // when muted, show placeholder
        if (!videoPub.muted) {
          this.videoPub = videoPub;
          return;
        }
      }
      this.videoPub = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    var videoPub = this.videoPub;
    if (videoPub != null) {
      return VideoTrackRenderer(videoPub.track as VideoTrack);
    } else {
      return Container(
        color: Colors.grey,
      );
    }
  }
}
