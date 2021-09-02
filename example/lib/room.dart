import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:livekit_example/widgets/controls.dart';
import 'package:provider/provider.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

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

  void _onConnected() async {
    // video will fail when running in ios simulator
    try {
      final localVideo = await LocalVideoTrack.createCameraTrack();
      await widget.room.localParticipant.publishVideoTrack(
        localVideo,
        // options: const TrackPublishOptions(
        //   simulcast: true,
        // ),
      );
    } catch (e) {
      print('could not publish video: $e');
    }

    final localAudio = await LocalAudioTrack.createTrack();
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
    final context = _lastContext;
    print('disconnected: $context');
    if (context != null) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    _lastContext = context;

    final mainWidgets = <Widget>[];
    final participants = this.participants;
    if (participants.isNotEmpty) {
      mainWidgets.add(Expanded(child: VideoView(participants.first)));
    } else {
      mainWidgets.add(Expanded(child: Container()));
    }

    if (participants.length > 1) {
      final videoList = ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: participants.length - 1,
        itemBuilder: (BuildContext context, int index) => Container(
          width: 100,
          height: 100,
          padding: const EdgeInsets.all(2),
          child: VideoView(participants[index + 1], quality: VideoQuality.LOW),
        ),
      );
      mainWidgets.add(SizedBox(
        height: 100,
        child: videoList,
      ));
    }

    mainWidgets.add(Controls(widget.room));
    //
    return Scaffold(
      // with a provider, any child/descendent widget can be updated if they
      // are a Consumer of Room.
      body: ChangeNotifierProvider.value(
        value: widget.room,
        child: Column(
          children: mainWidgets,
        ),
      ),
    );
  }
}

// displays a participant in view
class VideoView extends StatefulWidget {
  //
  final Participant participant;
  final VideoQuality quality;

  const VideoView(
    this.participant, {
    this.quality = VideoQuality.MEDIUM,
    Key? key,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _VideoViewState();
}

class _VideoViewState extends State<VideoView> with ParticipantDelegate {
  //
  TrackPublication? videoPub;

  @override
  void initState() {
    super.initState();
    widget.participant.addListener(_onParticipantChanged);
    _onParticipantChanged();
  }

  @override
  void dispose() {
    widget.participant.removeListener(_onParticipantChanged);
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
    final subscribedVideos = widget.participant.videoTracks.values.where((pub) {
      return pub.kind == TrackType.VIDEO && !pub.isScreenShare && pub.subscribed;
    });
    setState(() {
      if (subscribedVideos.isNotEmpty) {
        final videoPub = subscribedVideos.first;
        if (videoPub is RemoteTrackPublication) {
          videoPub.videoQuality = widget.quality;
        }
        // when muted, show placeholder
        if (!videoPub.muted) {
          this.videoPub = videoPub;
          return;
        }
      }
      videoPub = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final videoPub = this.videoPub;
    if (videoPub == null) {
      return Container(
        color: Colors.grey,
      );
    }

    return VideoTrackRenderer(
      videoPub.track as VideoTrack,
      fit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
    );
  }
}
