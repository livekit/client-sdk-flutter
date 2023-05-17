import 'dart:js' as js;

import 'package:platform_detect/platform_detect.dart';

import '../platform.dart';

PlatformType lkPlatformImplementation() => PlatformType.web;

bool lkE2EESupportedImplementation() {
  return isInsertableStreamSupported() || isScriptTransformSupported();
}

bool isScriptTransformSupported() {
  return js.context['RTCRtpScriptTransform'] != null;
}

bool isInsertableStreamSupported() {
  return js.context['RTCRtpSender'] != null &&
      js.context['RTCRtpSender']['prototype']['createEncodedStreams'] != null;
}

BrowserType lkBrowserImplementation() {
  if (browser.isChrome) return BrowserType.chrome;
  if (browser.isFirefox) return BrowserType.firefox;
  if (browser.isSafari) return BrowserType.safari;
  if (browser.isInternetExplorer) return BrowserType.internetExplorer;
  if (browser.isWKWebView) return BrowserType.wkWebView;
  return BrowserType.unknown;
}
