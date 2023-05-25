import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';

enum StatsType {
  kUnknown,
  kLocalAudioSender,
  kLocalVideoSender,
  kRemoteAudioReceiver,
  kRemoteVideoReceiver,
}

class ParticipantStatsWidget extends StatefulWidget {
  const ParticipantStatsWidget({Key? key, required this.participant})
      : super(key: key);
  final Participant participant;
  @override
  State<StatefulWidget> createState() => _ParticipantStatsWidgetState();
}

class _ParticipantStatsWidgetState extends State<ParticipantStatsWidget> {
  List<EventsListener<TrackEvent>> listeners = [];
  StatsType statsType = StatsType.kUnknown;
  Map<String, String> stats = {};

  void _setUpListener(Track track) {
    var listener = track.createListener();
    listeners.add(listener);
    if (track is LocalVideoTrack) {
      statsType = StatsType.kLocalVideoSender;
      listener.on<VideoSenderStatsEvent>((event) {
        setState(() {
          stats['video tx'] = '${event.currentBitrate.toInt()} kpbs';
          event.stats.forEach((key, value) {
            stats[key] =
                '${value.frameWidth}x${value.frameHeight} ${value.framesPerSecond?.toDouble()}fps \n qualityLimitationReason: ${value.qualityLimitationReason}';
          });
        });
      });
    } else if (track is RemoteVideoTrack) {
      statsType = StatsType.kRemoteVideoReceiver;
      listener.on<VideoReceiverStatsEvent>((event) {
        setState(() {
          stats['video rx'] = '${event.currentBitrate.toInt()} kpbs';
          stats['video size'] =
              '${event.stats.frameWidth}x${event.stats.frameHeight} ${event.stats.framesPerSecond?.toDouble()}fps';
          stats['video jitter'] = '${event.stats.jitter} s';
          stats['video decoder'] = '${event.stats.decoderImplementation}';
          //stats['video packets lost'] = '${event.stats.packetsLost}';
          //stats['video packets received'] = '${event.stats.packetsReceived}';
          stats['video frames received'] = '${event.stats.framesReceived}';
          stats['video frames decoded'] = '${event.stats.framesDecoded}';
          stats['video frames dropped'] = '${event.stats.framesDropped}';
        });
      });
    } else if (track is LocalAudioTrack) {
      statsType = StatsType.kLocalAudioSender;
      listener.on<AudioSenderStatsEvent>((event) {
        setState(() {
          stats['audio tx'] = '${event.currentBitrate.toInt()} kpbs';
        });
      });
    } else if (track is RemoteAudioTrack) {
      statsType = StatsType.kRemoteAudioReceiver;
      listener.on<AudioReceiverStatsEvent>((event) {
        setState(() {
          stats['audio rx'] = '${event.currentBitrate.toInt()} kpbs';
          stats['audio jitter'] = '${event.stats.jitter} s';
          //stats['audio concealed samples'] =
          //    '${event.stats.concealedSamples} / ${event.stats.concealmentEvents}';

          stats['audio packets lost'] = '${event.stats.packetsLost}';
          stats['audio packets received'] = '${event.stats.packetsReceived}';
        });
      });
    }
  }

  _onParticipantChanged() {
    for (var element in listeners) {
      element.dispose();
    }
    listeners.clear();
    for (var track in [
      ...widget.participant.videoTracks,
      ...widget.participant.audioTracks
    ]) {
      if (track.track != null) {
        _setUpListener(track.track!);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    widget.participant.addListener(_onParticipantChanged);
    // trigger initial change
    _onParticipantChanged();
  }

  @override
  void deactivate() {
    for (var element in listeners) {
      element.dispose();
    }
    widget.participant.removeListener(_onParticipantChanged);
    super.deactivate();
  }

  num sendBitrate = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.3),
      padding: const EdgeInsets.symmetric(
        vertical: 8,
        horizontal: 8,
      ),
      child: Column(
          children:
              stats.entries.map((e) => Text('${e.key}: ${e.value}')).toList()),
    );
  }
}
