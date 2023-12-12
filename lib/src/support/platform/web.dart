// Copyright 2023 LiveKit, Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

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

BrowserVersion lkBrowserVersionImplementation() => BrowserVersion(
    browser.version.major, browser.version.minor, browser.version.patch);
