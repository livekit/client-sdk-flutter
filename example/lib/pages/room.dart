import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../exts.dart';
import '../utils.dart';
import '../widgets/controls.dart';
import '../widgets/participant.dart';
import '../widgets/participant_grid_tile.dart';

class RoomPage extends StatefulWidget {
  //
  final Room room;
  final EventsListener<RoomEvent> listener;

  const RoomPage(
    this.room,
    this.listener, {
    Key? key,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _RoomPageState();
}

class _RoomPageState extends State<RoomPage> with WidgetsBindingObserver {
  List<Participant> participantTracks = [];
  EventsListener<RoomEvent> get _listener => widget.listener;
  bool get fastConnection => widget.room.engine.fastConnectOptions != null;
  bool get autoSubscribe => widget.room.connectOptions.autoSubscribe;
  bool gridView = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // add callback for a `RoomEvent` as opposed to a `ParticipantEvent`
    widget.room.addListener(_onRoomDidUpdate);
    // add callbacks for finer grained events
    _setUpListeners();
    _sortParticipants();
    WidgetsBindingCompatible.instance?.addPostFrameCallback((_) {
      if (!fastConnection) {
        _askPublish();
      }
    });

    if (lkPlatformIsMobile()) {
      Hardware.instance.setSpeakerphoneOn(true);
    }

    if (lkPlatformIsDesktop()) {
      onWindowShouldClose = () async {
        unawaited(widget.room.disconnect());
        await _listener.waitFor<RoomDisconnectedEvent>(
            duration: const Duration(seconds: 5));
      };
    }
  }

  @override
  void dispose() {
    // always dispose listener
    (() async {
      widget.room.removeListener(_onRoomDidUpdate);
      await _listener.dispose();
      await widget.room.dispose();
    })();
    WidgetsBinding.instance.removeObserver(this);
    onWindowShouldClose = null;
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    setState(() {});
    if (autoSubscribe) return;
    if (state == AppLifecycleState.resumed) {
      for (var p in participantTracks) {
        if (p.hasVideo && participantSubscriptions.containsKey(p.identity)) {
          (p as RemoteParticipant).videoTracks.firstOrNull?.subscribe();
        }
      }
    } else if (state == AppLifecycleState.paused) {
      for (var p in participantTracks) {
        if (p.hasVideo && participantSubscriptions.containsKey(p.identity)) {
          (p as RemoteParticipant).videoTracks.firstOrNull?.unsubscribe();
        }
      }
    }
  }

  /// for more information, see [event types](https://docs.livekit.io/client/events/#events)
  void _setUpListeners() => _listener
    ..on<RoomDisconnectedEvent>((event) async {
      if (event.reason != null) {
        print('Room disconnected: reason => ${event.reason}');
      }
      WidgetsBindingCompatible.instance
          ?.addPostFrameCallback((timeStamp) => Navigator.pop(context));
    })
    ..on<ParticipantEvent>((event) {
      print('Participant event');
      // sort participants on many track events as noted in documentation linked above
      _sortParticipants();
    })
    ..on<RoomRecordingStatusChanged>((event) {
      context.showRecordingStatusChangedDialog(event.activeRecording);
    })
    ..on<LocalTrackPublishedEvent>((_) => _sortParticipants())
    ..on<LocalTrackUnpublishedEvent>((_) => _sortParticipants())
    ..on<TrackSubscribedEvent>((_) => _sortParticipants())
    ..on<TrackUnsubscribedEvent>((_) => _sortParticipants())
    ..on<ParticipantConnectedEvent>((event) {
      print('Participant connected: ${event.participant.identity}');
    })
    ..on<ParticipantDisconnectedEvent>((event) {
      print('Participant disconnected: ${event.participant.identity}');
    })
    ..on<TrackE2EEStateEvent>(_onE2EEStateEvent)
    ..on<ParticipantNameUpdatedEvent>((event) {
      print(
          'Participant name updated: ${event.participant.identity}, name => ${event.name}');
      _sortParticipants();
    })
    ..on<ParticipantMetadataUpdatedEvent>((event) {
      print(
          'Participant metadata updated: ${event.participant.identity}, metadata => ${event.metadata}');
    })
    ..on<RoomMetadataChangedEvent>((event) {
      print('Room metadata changed: ${event.metadata}');
    })
    ..on<DataReceivedEvent>((event) {
      String decoded = 'Failed to decode';
      try {
        decoded = utf8.decode(event.data);
      } catch (_) {
        print('Failed to decode: $_');
      }
      context.showDataReceivedDialog(decoded);
    })
    ..on<AudioPlaybackStatusChanged>((event) async {
      if (!widget.room.canPlaybackAudio) {
        print('Audio playback failed for iOS Safari ..........');
        bool? yesno = await context.showPlayAudioManuallyDialog();
        if (yesno == true) {
          await widget.room.startAudio();
        }
      }
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

  void _onE2EEStateEvent(TrackE2EEStateEvent e2eeState) {
    print('e2ee state: $e2eeState');
  }

  void _sortParticipants() {
    List<Participant> sortedParticipants = [];
    for (var participant in widget.room.participants.values) {
      sortedParticipants.add(participant);
    }
    // sort speakers for the grid
    sortedParticipants.sort((a, b) {
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

    if (widget.room.localParticipant != null) {
      sortedParticipants.add(widget.room.localParticipant!);
    }

    setState(() {
      participantTracks = [
        ...sortedParticipants,
      ];
    });
  }

  void subscribeToVideoTracks(RemoteParticipant participant) async {
    if (participantSubscriptions[participant.identity] == true) {
      return;
    }
    participantSubscriptions[participant.identity] = true;
    await participant.videoTracks.firstOrNull?.subscribe();
  }

  void unSubscribeToVideoTracks(RemoteParticipant participant) async {
    if (participantSubscriptions[participant.identity] == false) {
      return;
    }
    participantSubscriptions[participant.identity] = false;
    await participant.videoTracks.firstOrNull?.unsubscribe();
  }

  Map<String, bool> visibleParticipants = {};
  Map<String, bool> participantSubscriptions = {};

  Widget _widgetForParticipant(int index) {
    final participant = participantTracks[index];
    return VisibilityDetector(
      key: Key(participant.identity),
      onVisibilityChanged: (info) {
        if (autoSubscribe) return;
        final bool isVisible = info.visibleFraction > 0;
        final bool isCompletelyGone = info.visibleFraction == 0;
        final bool isSubscribed =
            participantSubscriptions[participant.identity] ?? false;
        final bool shouldSubscribe =
            !isSubscribed && isVisible && participant is! LocalParticipant;

        if (shouldSubscribe) {
          subscribeToVideoTracks(
            participant as RemoteParticipant,
          );
          visibleParticipants[participant.identity] = true;
        } else if (participant is! LocalParticipant && isCompletelyGone) {
          unSubscribeToVideoTracks(
            participant as RemoteParticipant,
          );
          visibleParticipants.remove(
            participant.identity,
          );
        }
      },
      child: SizedBox(
        width: 240,
        height: 180,
        child: ParticipantGridTile(
          participantTracks[index],
          participantSubscriptions,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(
            'Room: ${widget.room.name}',
            style: const TextStyle(color: Colors.white),
          ),
          actions: [
            IconButton(
              icon: Icon(
                Icons.view_module,
                color: gridView ? Colors.green : Colors.white,
              ),
              onPressed: () {
                setState(() {
                  gridView = true;
                });
              },
            ),
            IconButton(
              icon: Icon(
                Icons.view_sidebar,
                color: !gridView ? Colors.green : Colors.white,
              ),
              onPressed: () {
                setState(() {
                  gridView = false;
                });
              },
            ),
            SizedBox.fromSize(
              size: const Size(42, 10),
            )
          ],
        ),
        body: Stack(
          children: [
            if (gridView)
              CustomScrollView(
                slivers: [
                  SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 300.0,
                      mainAxisSpacing: 10.0,
                      crossAxisSpacing: 10.0,
                      childAspectRatio: 1.5,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (BuildContext context, int index) =>
                          _widgetForParticipant(index),
                      childCount: participantTracks.length,
                    ),
                  ),
                ],
              ),
            if (widget.room.localParticipant != null && gridView)
              Positioned(
                left: 0,
                right: 0,
                bottom: 20,
                child: SafeArea(
                  top: false,
                  child: ControlsWidget(
                      widget.room, widget.room.localParticipant!),
                ),
              ),
            if (!gridView)
              Column(
                children: [
                  Expanded(
                      child: participantTracks.isNotEmpty
                          ? VisibilityDetector(
                              key: Key(participantTracks.first.identity),
                              onVisibilityChanged: (info) {
                                if (autoSubscribe) return;
                                final bool isVisible = info.visibleFraction > 0;
                                final bool isCompletelyGone =
                                    info.visibleFraction == 0;
                                final bool isSubscribed =
                                    participantSubscriptions[
                                            participantTracks.first.identity] ??
                                        false;
                                final bool shouldSubscribe = !isSubscribed &&
                                    isVisible &&
                                    participantTracks.first
                                        is! LocalParticipant;

                                if (shouldSubscribe) {
                                  subscribeToVideoTracks(
                                    participantTracks.first
                                        as RemoteParticipant,
                                  );
                                  visibleParticipants[
                                      participantTracks.first.identity] = true;
                                } else if (participantTracks.first
                                        is! LocalParticipant &&
                                    isCompletelyGone) {
                                  unSubscribeToVideoTracks(
                                    participantTracks.first
                                        as RemoteParticipant,
                                  );
                                  visibleParticipants.remove(
                                    participantTracks.first.identity,
                                  );
                                }
                              },
                              child: ParticipantWidget.widgetFor(
                                  participantTracks.first,
                                  showStatsLayer: true),
                            )
                          : Container()),
                  if (widget.room.localParticipant != null)
                    SafeArea(
                      top: false,
                      child: ControlsWidget(
                          widget.room, widget.room.localParticipant!),
                    )
                ],
              ),
            if (!gridView)
              Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  child: SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: math.max(0, participantTracks.length - 1),
                      itemBuilder: (BuildContext context, int index) =>
                          _widgetForParticipant(index + 1),
                    ),
                  )),
          ],
        ),
      );
}
