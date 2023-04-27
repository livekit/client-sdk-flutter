import 'dart:io';
import 'platform/io.dart' if (dart.library.html) 'platform/web.dart';

// Returns the current platform which works for both web and devices.
PlatformType lkPlatform() => lkPlatformImplementation();

bool lkPlatformIs(PlatformType type) => lkPlatform() == type;

bool lkPlatformSupportsE2EE() => lkE2EESupportedImplementation();

bool lkPlatformIsTest() => Platform.environment.containsKey('FLUTTER_TEST');

BrowserType lkBrowser() => lkBrowserImplementation();

enum PlatformType {
  web,
  windows,
  linux,
  macOS,
  android,
  fuchsia,
  iOS,
}

enum BrowserType {
  chrome,
  firefox,
  safari,
  internetExplorer,
  wkWebView,
  unknown,
}
