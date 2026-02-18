// Copyright 2024 LiveKit, Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'dart:math' as math;

import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;
import 'package:meta/meta.dart';

import '../events.dart';
import '../logger.dart';
import '../types/other.dart';

typedef PendingTrackSubscriber = Future<bool> Function(PendingTrack entry);
typedef TrackExceptionEmitter = void Function(TrackSubscriptionExceptionEvent event);

/// Helper that queues subscriber tracks when participant metadata isn't ready yet.
@internal
class PendingTrackQueue {
  final int maxSize;
  final int _maxPerParticipant;
  Duration _queueTtl;
  Duration _metadataTimeout;
  final TrackExceptionEmitter emitException;

  // keyed by participant sid
  final Map<String, List<PendingTrack>> _pending = {};

  PendingTrackQueue({
    required Duration metadataTimeout,
    required this.emitException,
    this.maxSize = 100,
  })  : _metadataTimeout = metadataTimeout,
        _queueTtl = _deriveQueueTtl(metadataTimeout),
        // Keep any single participant from starving others by capping their share
        // to roughly 25% of the total queue capacity (at least one slot).
        _maxPerParticipant = math.max(1, (maxSize / 4).floor());

  Duration get ttl => _queueTtl;

  Duration get metadataTimeout => _metadataTimeout;

  @visibleForTesting
  PendingTrackQueueStats get stats => _buildStats();

  @visibleForTesting
  List<PendingTrack> debugPendingFor(String participantSid) =>
      List<PendingTrack>.unmodifiable(_pending[participantSid] ?? const []);

  bool get hasPending => _pending.values.any((entries) => entries.isNotEmpty);

  void updateTimeouts(Duration metadataTimeout) {
    _metadataTimeout = metadataTimeout;
    _queueTtl = _deriveQueueTtl(metadataTimeout);
    refreshAll(reason: 'timeouts updated');
  }

  void clear({String reason = 'manual clear'}) {
    final currentStats = stats;
    if (currentStats.totalEntries > 0) {
      logger.finer('Clearing pending track queue reason:$reason total:${currentStats.totalEntries}');
    }
    _pending.clear();
  }

  void refreshParticipant(String participantSid, {String reason = 'metadata progress'}) {
    final entries = _pending[participantSid];
    if (entries == null || entries.isEmpty) return;
    final newExpiry = _newExpiry();
    for (final entry in entries) {
      entry.expiresAt = newExpiry;
    }
    logger.finer('Refreshed ${entries.length} pending tracks for participantSid:$participantSid reason:$reason');
  }

  void refreshAll({String reason = 'manual refresh'}) {
    if (!hasPending) return;
    final newExpiry = _newExpiry();
    var refreshed = 0;
    _pending.forEach((sid, list) {
      for (final entry in list) {
        entry.expiresAt = newExpiry;
        refreshed++;
      }
    });
    if (refreshed > 0) {
      logger.finer('Refreshed ${refreshed} pending tracks reason:$reason');
    }
  }

  void removeParticipant(String participantSid, {String reason = 'participant removed'}) {
    final removed = _pending.remove(participantSid);
    if (removed == null || removed.isEmpty) return;
    final now = DateTime.now();
    final maxAge = removed
        .map((entry) => now.difference(entry.enqueuedAt))
        .fold<Duration>(Duration.zero, (acc, value) => value > acc ? value : acc);
    logger.finer(
      'Removed ${removed.length} pending tracks sid:$participantSid reason:$reason maxAgeMs:${maxAge.inMilliseconds}',
    );
    for (final item in removed) {
      emitException(
        TrackSubscriptionExceptionEvent(
          participant: null,
          sid: item.trackSid,
          reason: TrackSubscribeFailReason.noParticipantFound,
        ),
      );
    }
  }

  void enqueue({
    required rtc.MediaStreamTrack track,
    required rtc.MediaStream stream,
    required rtc.RTCRtpReceiver? receiver,
    required String participantSid,
    required String trackSid,
    required ConnectionState connectionState,
  }) {
    // If we're already disconnected, drop immediately.
    if (connectionState == ConnectionState.disconnected) {
      final event = TrackSubscriptionExceptionEvent(
        participant: null,
        sid: trackSid,
        reason: TrackSubscribeFailReason.noParticipantFound,
      );
      logger.warning('Dropping pending track while disconnected trackSid:$trackSid participantSid:$participantSid');
      emitException(event);
      return;
    }

    _removeExpired();

    final listForParticipant = _pending.putIfAbsent(participantSid, () => []);
    if (listForParticipant.length >= _maxPerParticipant) {
      _dropWithException(
        participantSid: participantSid,
        trackSid: trackSid,
        reason: 'per-participant capacity reached ($_maxPerParticipant)',
      );
      return;
    }

    final totalPending = _pending.values.fold<int>(0, (sum, list) => sum + list.length);
    if (totalPending >= maxSize) {
      _dropWithException(
        participantSid: participantSid,
        trackSid: trackSid,
        reason: 'global capacity reached ($maxSize)',
      );
      return;
    }

    final now = DateTime.now();
    final expiresAt = now.add(_queueTtl);
    logger.fine(
      'Queueing pending trackSid:$trackSid participantSid:$participantSid pending=${totalPending + 1} '
      'participantPending=${listForParticipant.length + 1}',
    );
    final entry = PendingTrack(
      track: track,
      stream: stream,
      receiver: receiver,
      participantSid: participantSid,
      trackSid: trackSid,
      enqueuedAt: now,
      expiresAt: expiresAt,
    );
    listForParticipant.add(entry);
  }

  @internal
  Future<PendingTrackQueueFlushResult> flush({
    required bool isConnected,
    String? participantSid,
    required PendingTrackSubscriber subscriber,
  }) async {
    _removeExpired();
    if (!isConnected) {
      return PendingTrackQueueFlushResult(
        attempted: 0,
        succeeded: 0,
        transientFailures: 0,
        hasPending: hasPending,
        skippedForDisconnect: true,
      );
    }

    final Iterable<PendingTrack> source = participantSid != null
        ? List<PendingTrack>.from(_pending[participantSid] ?? const [])
        : _pending.values.expand((e) => e).toList();

    var attempted = 0;
    var succeeded = 0;
    var transientFailures = 0;

    for (final item in source) {
      if (!item.beginProcessing()) {
        continue;
      }

      attempted++;
      var success = false;
      try {
        success = await subscriber(item);
      } catch (error, stack) {
        logger.warning(
          'Pending track subscriber threw trackSid:${item.trackSid} participantSid:${item.participantSid}',
          error,
          stack,
        );
      } finally {
        item.endProcessing();
      }

      if (success) {
        succeeded++;
        _pending[item.participantSid]?.remove(item);
        if ((_pending[item.participantSid]?.isEmpty ?? false)) {
          _pending.remove(item.participantSid);
        }
      } else {
        transientFailures++;
        item.retryCount += 1;
      }
    }

    return PendingTrackQueueFlushResult(
      attempted: attempted,
      succeeded: succeeded,
      transientFailures: transientFailures,
      hasPending: hasPending,
      skippedForDisconnect: false,
    );
  }

  void _removeExpired() {
    final now = DateTime.now();
    final expiredEntries = <PendingTrack>[];
    _pending.removeWhere((sid, list) {
      list.removeWhere((item) {
        if (item.expiresAt.isBefore(now)) {
          expiredEntries.add(item);
          return true;
        }
        return false;
      });
      return list.isEmpty;
    });

    for (final item in expiredEntries) {
      final age = now.difference(item.enqueuedAt);
      logger.warning(
        'Pending track expired (ttl) trackSid:${item.trackSid} participantSid:${item.participantSid} '
        'ageMs:${age.inMilliseconds}',
      );
      emitException(
        TrackSubscriptionExceptionEvent(
          participant: null,
          sid: item.trackSid,
          reason: TrackSubscribeFailReason.noParticipantFound,
        ),
      );
    }
  }

  static Duration _deriveQueueTtl(Duration subscribeTimeout) {
    final multiplied = Duration(milliseconds: subscribeTimeout.inMilliseconds * 3);
    const minTtl = Duration(seconds: 30);
    return multiplied >= minTtl ? multiplied : minTtl;
  }

  DateTime _newExpiry() => DateTime.now().add(_queueTtl);

  PendingTrackQueueStats _buildStats() {
    var total = 0;
    Duration? oldest;
    final perParticipant = <String, int>{};
    final now = DateTime.now();
    _pending.forEach((sid, list) {
      total += list.length;
      perParticipant[sid] = list.length;
      for (final entry in list) {
        final age = now.difference(entry.enqueuedAt);
        if (oldest == null || age > oldest!) {
          oldest = age;
        }
      }
    });
    return PendingTrackQueueStats(
      totalEntries: total,
      entriesPerParticipant: perParticipant,
      oldestEntryAge: oldest,
    );
  }

  void _dropWithException({
    required String participantSid,
    required String trackSid,
    required String reason,
  }) {
    final event = TrackSubscriptionExceptionEvent(
      participant: null,
      sid: trackSid,
      reason: TrackSubscribeFailReason.noParticipantFound,
    );
    logger.severe(
      'Pending track queue drop trackSid:$trackSid participantSid:$participantSid reason:$reason',
    );
    emitException(event);
  }
}

@internal
class PendingTrack {
  final rtc.MediaStreamTrack track;
  final rtc.MediaStream stream;
  final rtc.RTCRtpReceiver? receiver;
  final String participantSid;
  final String trackSid;
  final DateTime enqueuedAt;
  DateTime expiresAt;
  bool _processing = false;
  int retryCount = 0;

  PendingTrack({
    required this.track,
    required this.stream,
    required this.receiver,
    required this.participantSid,
    required this.trackSid,
    required this.enqueuedAt,
    required this.expiresAt,
  });

  bool beginProcessing() {
    if (_processing) return false;
    _processing = true;
    return true;
  }

  void endProcessing() {
    _processing = false;
  }
}

@internal
class PendingTrackQueueStats {
  final int totalEntries;
  final Map<String, int> entriesPerParticipant;
  final Duration? oldestEntryAge;

  const PendingTrackQueueStats({
    required this.totalEntries,
    required this.entriesPerParticipant,
    required this.oldestEntryAge,
  });

  bool get hasEntries => totalEntries > 0;

  @override
  String toString() =>
      'PendingTrackQueueStats(total:$totalEntries, oldestMs:${oldestEntryAge?.inMilliseconds}, perParticipant:$entriesPerParticipant)';
}

class PendingTrackQueueFlushResult {
  final int attempted;
  final int succeeded;
  final int transientFailures;
  final bool hasPending;
  final bool skippedForDisconnect;

  const PendingTrackQueueFlushResult({
    required this.attempted,
    required this.succeeded,
    required this.transientFailures,
    required this.hasPending,
    required this.skippedForDisconnect,
  });

  bool get needsRetry => hasPending && !skippedForDisconnect;
}
