import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';

import '../exts.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets/controls.dart';
import '../widgets/messages_panel.dart';
import '../widgets/participant.dart';
import '../widgets/participant_info.dart';

class RoomPage extends StatefulWidget {
  final Room room;
  final EventsListener<RoomEvent> listener;
  final bool fastConnection;

  const RoomPage(
    this.room,
    this.listener, {
    this.fastConnection = false,
    super.key,
  });

  @override
  State<StatefulWidget> createState() => _RoomPageState();
}

class _RoomPageState extends State<RoomPage> {
  static const _chatTopic = 'lk-example-chat';

  List<ParticipantTrack> participantTracks = [];
  EventsListener<RoomEvent> get _listener => widget.listener;
  bool get fastConnection => widget.fastConnection;

  final _messageCtrl = TextEditingController();
  final List<ExampleRoomMessage> _messages = [];

  bool _showMessagesPanel = false;
  bool _isReconnecting = false;
  String? _reconnectStatus;
  DateTime? _connectedAt;
  String? _focusedTrackId;
  Timer? _headerTimer;

  @override
  void initState() {
    super.initState();
    _connectedAt = DateTime.now();
    _headerTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    widget.room.addListener(_onRoomDidUpdate);
    _setUpListeners();
    _sortParticipants();
    WidgetsBindingCompatible.instance?.addPostFrameCallback((_) {
      if (!fastConnection) {
        _askPublish();
      }
    });

    if (lkPlatformIs(PlatformType.android)) {
      unawaited(Hardware.instance.setSpeakerphoneOn(true));
    }

    if (lkPlatformIsDesktop()) {
      onWindowShouldClose = () async {
        unawaited(widget.room.disconnect());
        await _listener.waitFor<RoomDisconnectedEvent>(
          duration: const Duration(seconds: 5),
        );
      };
    }
  }

  @override
  void dispose() {
    widget.room.removeListener(_onRoomDidUpdate);
    _headerTimer?.cancel();
    _messageCtrl.dispose();
    unawaited(_disposeRoomAsync());
    onWindowShouldClose = null;
    super.dispose();
  }

  Future<void> _disposeRoomAsync() async {
    await _listener.dispose();
    await widget.room.dispose();
  }

  void _setUpListeners() => _listener
    ..on<RoomConnectedEvent>((event) {
      print('Room connected: ${event.room.name}');
      if (!mounted) return;
      setState(() {
        _connectedAt = DateTime.now();
        _isReconnecting = false;
        _reconnectStatus = null;
      });
    })
    ..on<RoomReconnectingEvent>((event) {
      print('Room reconnecting: $event');
      if (!mounted) return;
      setState(() {
        _isReconnecting = true;
        _reconnectStatus = 'Reconnecting media';
      });
    })
    ..on<RoomResumingEvent>((event) {
      print('Room resuming: $event');
      if (!mounted) return;
      setState(() {
        _isReconnecting = true;
        _reconnectStatus = 'Resuming signal';
      });
    })
    ..on<RoomReconnectedEvent>((event) {
      print('Room reconnected: $event');
      if (!mounted) return;
      setState(() {
        _isReconnecting = false;
        _reconnectStatus = null;
      });
    })
    ..on<RoomDisconnectedEvent>((event) async {
      if (event.reason != null) {
        print('Room disconnected: reason => ${event.reason}');
      }
      WidgetsBindingCompatible.instance?.addPostFrameCallback((timeStamp) {
        if (!mounted) return;
        Navigator.popUntil(context, (route) => route.isFirst);
      });
    })
    ..on<ParticipantEvent>((event) {
      _sortParticipants();
    })
    ..on<RoomRecordingStatusChanged>((event) {
      unawaited(
        context.showRecordingStatusChangedDialog(event.activeRecording),
      );
    })
    ..on<RoomAttemptReconnectEvent>((event) {
      print(
        'Attempting to reconnect ${event.attempt}/${event.maxAttemptsRetry}, '
        '(${event.nextRetryDelaysInMs}ms delay until next attempt)',
      );
      if (!mounted) return;
      setState(() {
        _isReconnecting = true;
        _reconnectStatus = 'Reconnect attempt ${event.attempt}/${event.maxAttemptsRetry}';
      });
    })
    ..on<LocalTrackSubscribedEvent>((event) {
      print('Local track subscribed: ${event.trackSid}');
    })
    ..on<LocalTrackPublishedEvent>((_) => _sortParticipants())
    ..on<LocalTrackUnpublishedEvent>((_) => _sortParticipants())
    ..on<TrackSubscribedEvent>((_) => _sortParticipants())
    ..on<TrackUnsubscribedEvent>((_) => _sortParticipants())
    ..on<TrackE2EEStateEvent>(_onE2EEStateEvent)
    ..on<ParticipantNameUpdatedEvent>((event) {
      print(
        'Participant name updated: ${event.participant.identity}, name => ${event.name}',
      );
      _sortParticipants();
    })
    ..on<ParticipantMetadataUpdatedEvent>((event) {
      print(
        'Participant metadata updated: ${event.participant.identity}, metadata => ${event.metadata}',
      );
    })
    ..on<RoomMetadataChangedEvent>((event) {
      print('Room metadata changed: ${event.metadata}');
    })
    ..on<DataReceivedEvent>(_handleDataReceived)
    ..on<AudioPlaybackStatusChanged>((event) async {
      if (!widget.room.canPlaybackAudio) {
        print('Audio playback failed for iOS Safari ..........');
        final yesno = await context.showPlayAudioManuallyDialog();
        if (yesno == true) {
          await widget.room.startAudio();
        }
      }
    });

  void _askPublish() async {
    final result = await context.showPublishDialog();
    if (!mounted) return;
    if (result != true) return;
    try {
      await widget.room.localParticipant?.setCameraEnabled(true);
    } catch (error) {
      print('could not publish video: $error');
      if (!mounted) return;
      await context.showErrorDialog(error);
    }
    try {
      await widget.room.localParticipant?.setMicrophoneEnabled(true);
    } catch (error) {
      print('could not publish audio: $error');
      if (!mounted) return;
      await context.showErrorDialog(error);
    }
  }

  void _onRoomDidUpdate() {
    _sortParticipants();
  }

  void _onE2EEStateEvent(TrackE2EEStateEvent e2eeState) {
    print('e2ee state: $e2eeState');
  }

  void _handleDataReceived(DataReceivedEvent event) {
    var decoded = 'Failed to decode';
    try {
      decoded = utf8.decode(event.data);
    } catch (error) {
      print('Failed to decode data message: $error');
    }

    ExampleRoomMessage message;
    if (event.topic == _chatTopic) {
      try {
        final payload = jsonDecode(decoded) as Map<String, dynamic>;
        message = ExampleRoomMessage.fromJson(payload);
      } catch (error) {
        print('Failed to decode room message: $error');
        message = ExampleRoomMessage.system(decoded);
      }
    } else {
      final sender = event.participant?.identity ?? 'server';
      message = ExampleRoomMessage.system('Data from $sender: $decoded');
    }

    if (!mounted) return;
    setState(() {
      _messages.add(message);
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageCtrl.text.trim();
    final participant = widget.room.localParticipant;
    if (text.isEmpty || participant == null) return;

    final message = ExampleRoomMessage.chat(
      text: text,
      senderIdentity: participant.identity,
      isLocal: true,
    );

    setState(() {
      _messageCtrl.clear();
      _messages.add(message);
    });

    try {
      await participant.publishData(
        utf8.encode(jsonEncode(message.toJson())),
        reliable: true,
        topic: _chatTopic,
      );
    } catch (error) {
      print('Failed to send room message: $error');
      if (!mounted) return;
      await context.showErrorDialog(error);
    }
  }

  void _sortParticipants() {
    final userMediaTracks = <ParticipantTrack>[];
    final screenTracks = <ParticipantTrack>[];

    for (final participant in widget.room.remoteParticipants.values) {
      var hasVideoPublication = false;
      for (final publication in participant.videoTrackPublications) {
        hasVideoPublication = true;
        if (publication.isScreenShare) {
          screenTracks.add(
            ParticipantTrack(
              participant: participant,
              type: ParticipantTrackType.kScreenShare,
            ),
          );
        } else {
          userMediaTracks.add(ParticipantTrack(participant: participant));
        }
      }
      if (!hasVideoPublication) {
        userMediaTracks.add(ParticipantTrack(participant: participant));
      }
    }

    userMediaTracks.sort((a, b) {
      if (a.participant.isSpeaking && b.participant.isSpeaking) {
        return a.participant.audioLevel > b.participant.audioLevel ? -1 : 1;
      }

      final aSpokeAt = a.participant.lastSpokeAt?.millisecondsSinceEpoch ?? 0;
      final bSpokeAt = b.participant.lastSpokeAt?.millisecondsSinceEpoch ?? 0;

      if (aSpokeAt != bSpokeAt) {
        return aSpokeAt > bSpokeAt ? -1 : 1;
      }

      if (a.participant.hasVideo != b.participant.hasVideo) {
        return a.participant.hasVideo ? -1 : 1;
      }

      return a.participant.joinedAt.millisecondsSinceEpoch - b.participant.joinedAt.millisecondsSinceEpoch;
    });

    final localParticipant = widget.room.localParticipant;
    if (localParticipant != null) {
      var hasVideoPublication = false;
      for (final publication in localParticipant.videoTrackPublications) {
        hasVideoPublication = true;
        if (publication.isScreenShare) {
          screenTracks.add(
            ParticipantTrack(
              participant: localParticipant,
              type: ParticipantTrackType.kScreenShare,
            ),
          );
        } else {
          userMediaTracks.add(ParticipantTrack(participant: localParticipant));
        }
      }
      if (!hasVideoPublication) {
        userMediaTracks.add(ParticipantTrack(participant: localParticipant));
      }
    }

    final nextTracks = [...screenTracks, ...userMediaTracks];
    final focusedTrackStillVisible =
        _focusedTrackId == null || nextTracks.any((track) => _trackId(track) == _focusedTrackId);

    if (!mounted) return;
    setState(() {
      participantTracks = nextTracks;
      if (!focusedTrackStillVisible) {
        _focusedTrackId = null;
      }
    });
  }

  ParticipantTrack? _focusedTrack() {
    final focusedTrackId = _focusedTrackId;
    if (focusedTrackId == null) return null;
    for (final track in participantTracks) {
      if (_trackId(track) == focusedTrackId) return track;
    }
    return null;
  }

  String _trackId(ParticipantTrack track) => '${track.participant.sid}-${track.type.name}';

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              _RoomHeader(
                room: widget.room,
                connectedAt: _connectedAt,
                isReconnecting: _isReconnecting,
                reconnectStatus: _reconnectStatus,
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 900;
                    final messages = MessagesPanel(
                      messages: _messages,
                      controller: _messageCtrl,
                      onSend: () => unawaited(_sendMessage()),
                      onClose: () {
                        setState(() {
                          _showMessagesPanel = false;
                        });
                      },
                    );

                    if (!_showMessagesPanel) {
                      return _buildStage();
                    }

                    if (wide) {
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
                        child: Row(
                          children: [
                            Expanded(child: _buildStage()),
                            const SizedBox(width: 12),
                            SizedBox(width: 340, child: messages),
                          ],
                        ),
                      );
                    }

                    return Padding(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
                      child: Column(
                        children: [
                          Expanded(child: _buildStage()),
                          const SizedBox(height: 12),
                          SizedBox(height: 280, child: messages),
                        ],
                      ),
                    );
                  },
                ),
              ),
              if (widget.room.localParticipant != null)
                ControlsWidget(
                  widget.room,
                  widget.room.localParticipant!,
                  showMessagesPanel: _showMessagesPanel,
                  onToggleMessagesPanel: () {
                    setState(() {
                      _showMessagesPanel = !_showMessagesPanel;
                    });
                  },
                ),
            ],
          ),
        ),
      );

  Widget _buildStage() => LayoutBuilder(
        builder: (context, constraints) {
          if (participantTracks.isEmpty) {
            return const Center(child: Text('Waiting for participants'));
          }

          final focusedTrack = _focusedTrack();
          if (focusedTrack == null) {
            return _ParticipantGrid(
              tracks: participantTracks,
              trackId: _trackId,
              focusedTrackId: _focusedTrackId,
              onFocus: (track) {
                setState(() {
                  _focusedTrackId = _trackId(track);
                });
              },
            );
          }

          final supportingTracks =
              participantTracks.where((track) => _trackId(track) != _trackId(focusedTrack)).toList();
          final wide = constraints.maxWidth >= constraints.maxHeight;

          if (wide) {
            return Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: _ParticipantTile(
                      track: focusedTrack,
                      selected: true,
                      showStatsLayer: true,
                      onFocus: () {
                        setState(() {
                          _focusedTrackId = null;
                        });
                      },
                    ),
                  ),
                  if (supportingTracks.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 220,
                      child: _ParticipantStrip(
                        tracks: supportingTracks,
                        vertical: true,
                        onFocus: (track) {
                          setState(() {
                            _focusedTrackId = _trackId(track);
                          });
                        },
                      ),
                    ),
                  ],
                ],
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                Expanded(
                  child: _ParticipantTile(
                    track: focusedTrack,
                    selected: true,
                    showStatsLayer: true,
                    onFocus: () {
                      setState(() {
                        _focusedTrackId = null;
                      });
                    },
                  ),
                ),
                if (supportingTracks.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 124,
                    child: _ParticipantStrip(
                      tracks: supportingTracks,
                      vertical: false,
                      onFocus: (track) {
                        setState(() {
                          _focusedTrackId = _trackId(track);
                        });
                      },
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      );
}

class _RoomHeader extends StatelessWidget {
  const _RoomHeader({
    required this.room,
    required this.connectedAt,
    required this.isReconnecting,
    required this.reconnectStatus,
  });

  final Room room;
  final DateTime? connectedAt;
  final bool isReconnecting;
  final String? reconnectStatus;

  @override
  Widget build(BuildContext context) {
    final participantCount = room.remoteParticipants.length + (room.localParticipant == null ? 0 : 1);
    final localIdentity = room.localParticipant?.identity ?? 'local';
    final connectedFor = connectedAt == null ? null : DateTime.now().difference(connectedAt!);
    final serverDetails = [
      if (room.serverRegion != null) room.serverRegion,
      if (room.serverVersion != null) 'v${room.serverVersion}',
    ].join(' / ');

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: LKColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  room.name ?? 'LiveKit Room',
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  [
                    localIdentity,
                    '$participantCount participant${participantCount == 1 ? '' : 's'}',
                    if (connectedFor != null) '${connectedFor.inSeconds}s connected',
                    if (serverDetails.isNotEmpty) serverDetails,
                  ].join(' / '),
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: LKColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
          _StatusPill(
            label: reconnectStatus ?? (isReconnecting ? 'Reconnecting' : 'Connected'),
            icon: isReconnecting ? Icons.sync : Icons.check_circle,
            color: isReconnecting ? Colors.orange : LKColors.lkGreen,
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          border: Border.all(color: color.withValues(alpha: 0.35)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      );
}

class _ParticipantGrid extends StatelessWidget {
  const _ParticipantGrid({
    required this.tracks,
    required this.trackId,
    required this.focusedTrackId,
    required this.onFocus,
  });

  final List<ParticipantTrack> tracks;
  final String Function(ParticipantTrack track) trackId;
  final String? focusedTrackId;
  final ValueChanged<ParticipantTrack> onFocus;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          if (tracks.length == 1) {
            return Padding(
              padding: const EdgeInsets.all(8),
              child: _ParticipantTile(
                track: tracks.first,
                selected: false,
                showStatsLayer: true,
                onFocus: () => onFocus(tracks.first),
              ),
            );
          }

          final columns = _columnCount(constraints.maxWidth, tracks.length);
          return GridView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: tracks.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 16 / 9,
            ),
            itemBuilder: (context, index) {
              final track = tracks[index];
              return _ParticipantTile(
                track: track,
                selected: trackId(track) == focusedTrackId,
                showStatsLayer: index == 0,
                onFocus: () => onFocus(track),
              );
            },
          );
        },
      );

  int _columnCount(double width, int count) {
    if (count <= 1 || width < 560) return 1;
    if (width < 920) return 2;
    if (width < 1280) return 3;
    return 4;
  }
}

class _ParticipantStrip extends StatelessWidget {
  const _ParticipantStrip({
    required this.tracks,
    required this.vertical,
    required this.onFocus,
  });

  final List<ParticipantTrack> tracks;
  final bool vertical;
  final ValueChanged<ParticipantTrack> onFocus;

  @override
  Widget build(BuildContext context) => ListView.separated(
        scrollDirection: vertical ? Axis.vertical : Axis.horizontal,
        itemCount: tracks.length,
        separatorBuilder: (context, index) => SizedBox(width: vertical ? 0 : 8, height: vertical ? 8 : 0),
        itemBuilder: (context, index) {
          final track = tracks[index];
          return SizedBox(
            width: vertical ? double.infinity : 190,
            height: vertical ? 124 : double.infinity,
            child: _ParticipantTile(
              track: track,
              selected: false,
              showStatsLayer: false,
              onFocus: () => onFocus(track),
            ),
          );
        },
      );
}

class _ParticipantTile extends StatelessWidget {
  const _ParticipantTile({
    required this.track,
    required this.selected,
    required this.showStatsLayer,
    required this.onFocus,
  });

  final ParticipantTrack track;
  final bool selected;
  final bool showStatsLayer;
  final VoidCallback onFocus;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(
            color: selected ? LKColors.lkBlue : LKColors.border,
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(7),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ParticipantWidget.widgetFor(track, showStatsLayer: showStatsLayer),
              Positioned(
                right: 8,
                top: 8,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    tooltip: selected ? 'Clear focus' : 'Focus participant',
                    icon: Icon(
                      selected ? Icons.fullscreen_exit : Icons.center_focus_strong,
                    ),
                    onPressed: onFocus,
                  ),
                ),
              ),
              if (selected)
                Positioned(
                  left: 10,
                  top: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(
                      color: LKColors.lkBlue.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'FOCUSED',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
}
