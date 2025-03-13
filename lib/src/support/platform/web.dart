// Copyright 2024 LiveKit, Inc.
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

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter/foundation.dart';

import 'package:web/web.dart' as web;

import '../platform.dart';

PlatformType lkPlatformImplementation() => PlatformType.web;

bool lkPlatformIsWebMobileImplementation() {
  return (defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.android);
}

bool lkE2EESupportedImplementation() {
  return isInsertableStreamSupported() || isScriptTransformSupported();
}

bool isScriptTransformSupported() {
  return web.window
      .hasProperty('RTCRtpScriptTransform'.toJS)
      .isDefinedAndNotNull;
}

bool isInsertableStreamSupported() {
  return web.window.hasProperty('RTCRtpSender'.toJS).isDefinedAndNotNull &&
      ((web.window.getProperty('RTCRtpSender'.toJS) as JSObject)
              .getProperty('prototype'.toJS) as JSObject)
          .getProperty('createEncodedStreams'.toJS)
          .isDefinedAndNotNull;
}

BrowserType lkBrowserImplementation() {
  var ua = web.window.navigator.userAgent;
  var vendor = web.window.navigator.vendor;
  var appVersion = web.window.navigator.appVersion;
  if (web.window.navigator.vendor.contains('Google')) {
    return BrowserType.chrome;
  }
  if (ua.contains('Firefox')) return BrowserType.firefox;
  if (vendor.contains('Apple') && appVersion.contains('Version')) {
    return BrowserType.safari;
  }
  if (web.Device.isIE) return BrowserType.internetExplorer;
  if (ua.contains('Edg/')) return BrowserType.edge;
  if (web.Device.isWebKit) return BrowserType.wkWebView;
  return BrowserType.unknown;
}

BrowserVersion lkBrowserVersionImplementation() {
  var appVersion = web.window.navigator.appVersion;
  Match match =
      RegExp(r'Version/(\d+)(\.(\d+))?(\.(\d+))?').firstMatch(appVersion)!;
  var major = int.parse(match.group(1)!);
  var minor = int.parse(match.group(3) ?? '0');
  var patch = int.parse(match.group(5) ?? '0');

  return BrowserVersion(major, minor, patch);
}
