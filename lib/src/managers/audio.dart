import 'package:livekit_client/livekit_client.dart';
import 'package:livekit_client/src/logger.dart';

import '../events.dart';

enum AudioRecommendationType {
  listenOnly,
  publishOnly,
  listenAndPublish,
}

abstract class AudioManagerEvent implements LiveKitEvent {}

class AudioManagerUpdatedRecommendationEvent with AudioManagerEvent {
  final AudioRecommendationType type;
  const AudioManagerUpdatedRecommendationEvent({
    required this.type,
  });
}

class AudioManager {
  static AudioManager? _instance;
  // Initial state is listen
  AudioRecommendationType currentRecommendation = AudioRecommendationType.listenOnly;
  int _subscribeCounter = 0;
  int _publishCounter = 0;

  final events = EventsEmitter<AudioManagerEvent>();

  // Singleton
  factory AudioManager() {
    _instance ??= AudioManager();
    return _instance!;
  }

  Future<void> dispose() async {
    await events.dispose();
  }

  void incrementListen() {
    _subscribeCounter++;
    _onUpdate();
  }

  void decrementListen() {
    if (_subscribeCounter <= 0) return;
    _subscribeCounter--;
    _onUpdate();
  }

  void incrementPublish() {
    _publishCounter++;
    _onUpdate();
  }

  void decrementPublish() {
    if (_publishCounter <= 0) return;
    _publishCounter--;
    _onUpdate();
  }

  AudioRecommendationType _calculateRecommendation() {
    if (_publishCounter > 0 && _subscribeCounter == 0) {
      return AudioRecommendationType.publishOnly;
    } else if (_publishCounter > 0 && _subscribeCounter > 0) {
      return AudioRecommendationType.listenAndPublish;
    }
    // Default
    return AudioRecommendationType.listenOnly;
  }

  void _onUpdate() {
    final newRecommendation = _calculateRecommendation();
    if (currentRecommendation != newRecommendation) {
      currentRecommendation = newRecommendation;
      events.emit(AudioManagerUpdatedRecommendationEvent(type: currentRecommendation));
      logger.fine('[$runtimeType] updated recommendation ${currentRecommendation}');
    }
  }
}
