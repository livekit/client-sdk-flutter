// Copyright 2017 Workiva Inc.
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
import 'dart:html';

import 'package:platform_detect/src/browser.dart';
import 'package:platform_detect/src/navigator.dart';
import 'package:platform_detect/src/operating_system.dart';
import 'package:platform_detect/src/support.dart';

/// A test utility that allows a consumer to instruct the library to
/// respond as though it was running on a particular browser and / or
/// operating system.
///
/// Calling this method with no arguments will reset the library to its
/// default behavior.
void configurePlatformForTesting(
    {Browser? browser,
    OperatingSystem? operatingSystem,
    List<Feature>? features}) {
  _browser = browser;
  _operatingSystem = operatingSystem;
  _features = features;
}

Browser? _browser;

/// Current browser info
Browser get browser {
  if (_browser == null) {
    Browser.navigator = _HtmlNavigator();
    _browser = Browser.getCurrentBrowser();
  }

  return _browser!;
}

OperatingSystem? _operatingSystem;

/// Current operating system info
OperatingSystem get operatingSystem {
  if (_operatingSystem == null) {
    OperatingSystem.navigator = _HtmlNavigator();
    _operatingSystem = OperatingSystem.getCurrentOperatingSystem();
  }

  return _operatingSystem!;
}

List<Feature>? _features;

/// Current browser feature support info
List<Feature>? get features => _features;

class _HtmlNavigator implements NavigatorProvider {
  @override
  String get vendor => window.navigator.vendor;
  @override
  String get appVersion => window.navigator.appVersion;
  @override
  String get appName => window.navigator.appName;
  @override
  String get userAgent => window.navigator.userAgent;
}
