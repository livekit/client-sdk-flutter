// import 'package:audio_session/audio_session.dart' as _as;

// import '../events.dart';
// import '../logger.dart';
// import 'event.dart';

// // abstract class AudioManagerEvent implements LiveKitEvent {}

// // class AudioManagerUpdatedRecommendationEvent with AudioManagerEvent {
// //   final AudioTrackState type;
// //   const AudioManagerUpdatedRecommendationEvent({
// //     required this.type,
// //   });
// // }

// class AudioManager {
//   static AudioManager? _instance;
//   bool automaticManagementEnabled = true;
// // Initial state is listen
//   // AudioTrackState currentRecommendation = AudioTrackState.none;

//   // final events = EventsEmitter<AudioManagerEvent>();

//   AudioManager._() {
//     (() async {
//       // await _configureCurrentRecommendation();
//     })();
//   }

//   // Singleton
//   factory AudioManager() {
//     _instance ??= AudioManager._();
//     return _instance!;
//   }

//   Future<void> dispose() async {
//     // await events.dispose();
//   }

//   // Future<void> incrementSubscriptionCounter() async {
//   //   _subscribeCounter++;
//   //   await _onUpdate();
//   // }

//   // Future<void> decrementSubscriptionCounter() async {
//   //   if (_subscribeCounter <= 0) return;
//   //   _subscribeCounter--;
//   //   await _onUpdate();
//   // }

//   // Future<void> incrementPublishCounter() async {
//   //   _publishCounter++;
//   //   await _onUpdate();
//   // }

//   // Future<void> decrementPublishCounter() async {
//   //   if (_publishCounter <= 0) return;
//   //   _publishCounter--;
//   //   await _onUpdate();
//   // }

//   // static AudioTrackState computeAudioTrackState({
//   //   required int local,
//   //   required int remote,
//   // }) {
//   //   if (local > 0 && remote == 0) {
//   //     return AudioTrackState.localOnly;
//   //   } else if (local > 0 && remote > 0) {
//   //     return AudioTrackState.localAndRemote;
//   //   }
//   //   // Default
//   //   return AudioTrackState.remoteOnly;
//   // }

//   // Future<void> _onUpdate() async {
//   //   final newRecommendation = computeAudioTrackState();
//   //   if (currentRecommendation != newRecommendation) {
//   //     currentRecommendation = newRecommendation;
//   //     events.emit(AudioManagerUpdatedRecommendationEvent(type: currentRecommendation));
//   //     logger.fine('[$runtimeType] updated recommendation ${currentRecommendation}');
//   //     if (automaticManagementEnabled) {
//   //       await _configureCurrentRecommendation();
//   //     }
//   //   }
//   // }

// }
