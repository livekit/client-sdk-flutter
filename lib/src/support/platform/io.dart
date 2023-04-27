import 'dart:io';

import '../platform.dart';

PlatformType lkPlatformImplementation() {
  if (Platform.isWindows) return PlatformType.windows;
  if (Platform.isFuchsia) return PlatformType.fuchsia;
  if (Platform.isMacOS) return PlatformType.macOS;
  if (Platform.isLinux) return PlatformType.linux;
  if (Platform.isIOS) return PlatformType.iOS;
  if (Platform.isAndroid) return PlatformType.android;
  throw UnsupportedError('Unknown Platform');
}

bool lkE2EESupportedImplementation() {
  return [
    PlatformType.windows,
    PlatformType.linux,
    PlatformType.macOS,
    PlatformType.iOS,
    PlatformType.android,
  ].contains(lkPlatformImplementation());
}

BrowserType lkBrowserImplementation() {
  return BrowserType.unknown;
}
