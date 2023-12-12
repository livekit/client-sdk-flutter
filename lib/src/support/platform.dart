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

import 'dart:io';

import 'platform/io.dart' if (dart.library.html) 'platform/web.dart';

// Returns the current platform which works for both web and devices.
PlatformType lkPlatform() => lkPlatformImplementation();

bool lkPlatformIs(PlatformType type) => lkPlatform() == type;

bool lkPlatformIsMobile() =>
    [PlatformType.iOS, PlatformType.android].contains(lkPlatform());

bool lkPlatformIsDesktop() => [
      PlatformType.macOS,
      PlatformType.windows,
      PlatformType.linux
    ].contains(lkPlatform());

bool lkPlatformSupportsE2EE() => lkE2EESupportedImplementation();

bool lkPlatformIsTest() => Platform.environment.containsKey('FLUTTER_TEST');

BrowserType lkBrowser() => lkBrowserImplementation();

BrowserVersion lkBrowserVersion() => lkBrowserVersionImplementation();

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

class BrowserVersion {
  const BrowserVersion(this.major, this.minor, this.patch);

  /// The major version number: "1" in "1.2.3".
  final int major;

  /// The minor version number: "2" in "1.2.3".
  final int minor;

  /// The patch version number: "3" in "1.2.3".
  final int patch;
}
