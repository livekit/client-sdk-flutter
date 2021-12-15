import '../platform.dart';
import 'dart:io';

PlatformType lkPlatformImplementation() {
  if (Platform.isWindows) return PlatformType.windows;
  if (Platform.isFuchsia) return PlatformType.fuchsia;
  if (Platform.isMacOS) return PlatformType.macOS;
  if (Platform.isLinux) return PlatformType.linux;
  if (Platform.isIOS) return PlatformType.iOS;
  return PlatformType.android;
}
