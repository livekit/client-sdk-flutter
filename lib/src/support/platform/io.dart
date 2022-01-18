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
