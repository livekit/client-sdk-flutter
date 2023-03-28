import '../../livekit_client.dart';

enum E2EEState {
  kNew,
  kOk,
  kKeyRatcheted,
  kMissingKey,
  kEncryptionFailed,
  kDecryptionFailed,
  kInternalError,
}

/// The [E2EEState] on the track.
/// Emitted by [E2EEManager].
class TrackE2EEStateEvent with RoomEvent, ParticipantEvent {
  final Participant participant;
  final TrackPublication publication;
  final E2EEState state;
  const TrackE2EEStateEvent({
    required this.participant,
    required this.publication,
    required this.state,
  });

  @override
  String toString() => '${runtimeType}'
      '(participant: ${participant}, publication: ${publication}, state: ${state})';
}
