// Dart imports:
import 'dart:io';

// Flutter imports:
import 'package:flutter/services.dart';
import 'package:livekit_client/livekit_client.dart';

class ReplayKitChannel {
  static const String kReplayKitChannel =
      'io.livekit.example.flutter/replaykit-channel';

  static const MethodChannel _replayKitChannel =
      MethodChannel(kReplayKitChannel);

  static void listenMethodChannel(Room room) {
    _replayKitChannel.setMethodCallHandler((call) async {
      if (call.method == 'closeReplayKitFromNative') {
        if (!(room.localParticipant?.isScreenShareEnabled() ?? false)) {
          return;
        }

        await room.localParticipant?.setScreenShareEnabled(false);
      } else if (call.method == 'hasSampleBroadcast') {
        if (room.localParticipant?.isScreenShareEnabled() ?? true) return;

        await room.localParticipant?.setScreenShareEnabled(true);
      }
    });
  }

  static void startReplayKit() {
    if (!Platform.isIOS) return;

    _replayKitChannel.invokeMethod('startReplayKit');
  }

  static void closeReplayKit() {
    if (!Platform.isIOS) return;

    _replayKitChannel.invokeMethod('closeReplayKit');
  }
}
