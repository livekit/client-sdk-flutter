import 'package:livekit_client/src/logger.dart';
import 'package:audio_session/audio_session.dart' as _as;

import '../events.dart';
import 'event.dart';

enum AudioRecommendationType {
  playOnly,
  recordOnly,
  playAndRecord,
}

extension AudioRecommendationTypeExt on AudioRecommendationType {
  _as.AudioSessionConfiguration configuration() {
    //
    final playOnlyConfiguration = _as.AudioSessionConfiguration(
      avAudioSessionCategory: _as.AVAudioSessionCategory.playback,
      avAudioSessionCategoryOptions: _as.AVAudioSessionCategoryOptions.mixWithOthers &
          _as.AVAudioSessionCategoryOptions.allowBluetooth &
          _as.AVAudioSessionCategoryOptions.allowAirPlay &
          _as.AVAudioSessionCategoryOptions.defaultToSpeaker,
      avAudioSessionMode: _as.AVAudioSessionMode.spokenAudio,
      avAudioSessionRouteSharingPolicy: _as.AVAudioSessionRouteSharingPolicy.longFormAudio,
      avAudioSessionSetActiveOptions: _as.AVAudioSessionSetActiveOptions.none,
    );

    if (this == AudioRecommendationType.recordOnly) {
      return playOnlyConfiguration.copyWith(
        avAudioSessionCategory: _as.AVAudioSessionCategory.record,
        avAudioSessionCategoryOptions: _as.AVAudioSessionCategoryOptions.allowBluetooth,
        avAudioSessionMode: _as.AVAudioSessionMode.spokenAudio,
        avAudioSessionRouteSharingPolicy: _as.AVAudioSessionRouteSharingPolicy.defaultPolicy,
        avAudioSessionSetActiveOptions: _as.AVAudioSessionSetActiveOptions.none,
      );
    } else if (this == AudioRecommendationType.playAndRecord) {
      return playOnlyConfiguration.copyWith(
        avAudioSessionCategory: _as.AVAudioSessionCategory.playAndRecord,
        avAudioSessionCategoryOptions: _as.AVAudioSessionCategoryOptions.mixWithOthers &
            _as.AVAudioSessionCategoryOptions.allowBluetooth &
            _as.AVAudioSessionCategoryOptions.allowAirPlay &
            _as.AVAudioSessionCategoryOptions.defaultToSpeaker,
        avAudioSessionMode: _as.AVAudioSessionMode.voiceChat,
        avAudioSessionRouteSharingPolicy: _as.AVAudioSessionRouteSharingPolicy.defaultPolicy,
        avAudioSessionSetActiveOptions: _as.AVAudioSessionSetActiveOptions.none,
      );
    }

    return playOnlyConfiguration;
  }
}

abstract class AudioManagerEvent implements LiveKitEvent {}

class AudioManagerUpdatedRecommendationEvent with AudioManagerEvent {
  final AudioRecommendationType type;
  const AudioManagerUpdatedRecommendationEvent({
    required this.type,
  });
}

final x = AudioManager();

class AudioManager {
  static AudioManager? _instance;
  bool automaticManagementEnabled = true;
// Initial state is listen
  AudioRecommendationType currentRecommendation = AudioRecommendationType.playOnly;
  int _subscribeCounter = 0;
  int _publishCounter = 0;

  final events = EventsEmitter<AudioManagerEvent>();

  AudioManager._() {
    (() async {
      await _configureCurrentRecommendation();
    })();
  }

  // Singleton
  factory AudioManager() {
    _instance ??= AudioManager._();
    return _instance!;
  }

  Future<void> dispose() async {
    await events.dispose();
  }

  Future<void> incrementSubscriptionCounter() async {
    _subscribeCounter++;
    await _onUpdate();
  }

  Future<void> decrementSubscriptionCounter() async {
    if (_subscribeCounter <= 0) return;
    _subscribeCounter--;
    await _onUpdate();
  }

  Future<void> incrementPublishCounter() async {
    _publishCounter++;
    await _onUpdate();
  }

  Future<void> decrementPublishCounter() async {
    if (_publishCounter <= 0) return;
    _publishCounter--;
    await _onUpdate();
  }

  AudioRecommendationType _calculateRecommendation() {
    if (_publishCounter > 0 && _subscribeCounter == 0) {
      return AudioRecommendationType.recordOnly;
    } else if (_publishCounter > 0 && _subscribeCounter > 0) {
      return AudioRecommendationType.playAndRecord;
    }
    // Default
    return AudioRecommendationType.playOnly;
  }

  Future<void> _onUpdate() async {
    final newRecommendation = _calculateRecommendation();
    if (currentRecommendation != newRecommendation) {
      currentRecommendation = newRecommendation;
      events.emit(AudioManagerUpdatedRecommendationEvent(type: currentRecommendation));
      logger.fine('[$runtimeType] updated recommendation ${currentRecommendation}');
      if (automaticManagementEnabled) {
        await _configureCurrentRecommendation();
      }
    }
  }

  Future<void> _configureCurrentRecommendation() async {
    logger.fine('[$runtimeType] configuring for ${currentRecommendation}...');
    try {
      final _audioSession = await _as.AudioSession.instance;
      await _audioSession.configure(currentRecommendation.configuration());
      await _audioSession.setActive(true);
    } catch (error) {
      logger.warning('[$runtimeType] Failed to configure ${error}');
    }
  }
}
