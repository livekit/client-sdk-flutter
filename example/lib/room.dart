import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:provider/provider.dart';

class RoomWidget extends StatelessWidget with RoomDelegate {
  final Room _room;
  BuildContext? _lastContext;

  RoomWidget(this._room) {
    // Room widget is created after connected to the room
    // publish tracks to the room here.
    _onConnected();
    _room.delegate = this;
  }

  @override
  void onDisconnected() {
    var context = _lastContext;
    print("disconnected: $context");
    if (context != null) {
      Navigator.pop(context);
    }
  }

  _onConnected() async {
    var localVideo = await LocalVideoTrack.createCameraTrack();
    await _room.localParticipant.publishVideoTrack(localVideo);
    var localAudio = await LocalAudioTrack.createTrack();
    await _room.localParticipant.publishAudioTrack(localAudio);
  }

  @override
  Widget build(BuildContext context) {
    _lastContext = context;
    // with a provider, any child/descendent widget can be updated if they
    // are a Consumer of Room.
    return ChangeNotifierProvider.value(
        value: _room,
        child: Column(
          children: [
            Expanded(child: Consumer<Room>(builder: (context, room, child) {
              // ensures the video grid gets updated each time participants change
              return VideoGrid(room);
            }))
          ],
        ));
  }
}

class VideoGrid extends StatelessWidget {
  final Room room;
  final PageController controller = PageController(initialPage: 0);

  VideoGrid(this.room);

  List<Participant> get sortedParticipants {
    List<Participant> participants = [];
    participants.add(room.localParticipant);
    participants.addAll(room.participants.values);
    // TODO: sort speakers for the grid
    // participants.sort((a, b) {
    //   // loudest speaker first
    //   if (a.isSpeaking && b.isSpeaking) {
    //     if (a.audioLevel > b.audioLevel) {
    //       return -1;
    //     } else {x
    //       return 1;
    //     }
    //   }
    //   // speaker
    // });
    return participants;
  }

  @override
  Widget build(Object context) {
    List<Widget> pages = [];
    var participants = sortedParticipants;
    var numPages = (participants.length / 4.0).ceil();
    for (var i = 0; i < numPages; i++) {
      List<Widget> children = [];
      for (var j = 4 * i; j < participants.length; j++) {
        var participant = participants[j];
        children.add(VideoView(participant));
      }
      pages.add(GridView.count(
        crossAxisCount: 2,
        primary: false,
        children: children,
      ));
    }

    return PageView(
      scrollDirection: Axis.horizontal,
      controller: controller,
      children: pages,
    );
  }
}

class VideoView extends StatefulWidget {
  final Participant participant;

  VideoView(this.participant);

  @override
  State<StatefulWidget> createState() {
    return _VideoViewState();
  }
}

class _VideoViewState extends State<VideoView> with ParticipantDelegate {
  @override
  void initState() {
    super.initState();
    widget.participant.addListener(this._onParticipantChanged);
  }

  // register for change so Flutter will re-build the widget upon change
  void _onParticipantChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    widget.participant.removeListener(this._onParticipantChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var stackChildren = <Widget>[];
    var subscribedVideos = widget.participant.videoTracks.values.where((pub) {
      return pub.kind == TrackType.VIDEO &&
          !pub.isScreenShare &&
          pub.subscribed;
    });

    if (subscribedVideos.length > 0) {
      var videoPub = subscribedVideos.first;
      stackChildren.add(VideoTrackRenderer(videoPub.track as VideoTrack));
    }

    return Stack(
      children: stackChildren,
    );
  }
}
