import 'package:meta/meta.dart';

import '../proto/livekit_models.pb.dart' as lk_models;

@immutable
class ParticipantPermissions {
  final bool canSubscribe;
  final bool canPublish;
  final bool canPublishData;
  final bool hidden;
  final bool recorder;

  const ParticipantPermissions({
    this.canSubscribe = false,
    this.canPublish = false,
    this.canPublishData = false,
    this.hidden = false,
    this.recorder = false,
  });
}

extension ParticipantPermissionExt on lk_models.ParticipantPermission {
  ParticipantPermissions toLKType() => ParticipantPermissions(
        canSubscribe: canSubscribe,
        canPublish: canPublish,
        canPublishData: canPublishData,
        hidden: hidden,
        recorder: recorder,
      );
}
