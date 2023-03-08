import '../platform.dart';

import 'package:platform_detect/platform_detect.dart';

PlatformType lkPlatformImplementation() => PlatformType.web;

BrowserType lkBrowserImplementation() {
  if (browser.isChrome) return BrowserType.chrome;
  if (browser.isFirefox) return BrowserType.firefox;
  if (browser.isSafari) return BrowserType.safari;
  if (browser.isInternetExplorer) return BrowserType.internetExplorer;
  if (browser.isWKWebView) return BrowserType.wkWebView;
  return BrowserType.unknown;
}
