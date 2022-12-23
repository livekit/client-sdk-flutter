import 'package:flutter_webrtc/flutter_webrtc.dart';

bool isE2EESupported() {
  return WebRTC.platformIsMobile || WebRTC.platformIsDesktop;
}
