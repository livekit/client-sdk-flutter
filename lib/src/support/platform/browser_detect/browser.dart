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

import 'package:meta/meta.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:web/web.dart' as web;

import 'navigator.dart';

/// Matches a browser name with how it is represented in window.navigator
class Browser {
  static NavigatorProvider? navigator;

  static Browser getCurrentBrowser() {
    return _knownBrowsers.firstWhere(
        (browser) => navigator != null && browser._matchesNavigator(navigator!),
        orElse: () => UnknownBrowser);
  }

  @visibleForTesting
  void clearVersion() => _version = null;

  // ignore: non_constant_identifier_names
  static Browser UnknownBrowser =
      Browser('Unknown', (_) => false, (_) => Version(0, 0, 0));

  Browser(this.name, this._matchesNavigator, this._parseVersion,
      {this.className = ''});

  final String name;

  /// The CSS class value that should be used instead of lowercase [name] (optional).
  final String className;
  final bool Function(NavigatorProvider) _matchesNavigator;
  final Version Function(NavigatorProvider) _parseVersion;

  Version? _version;

  Version get version =>
      _version ??= _parseVersion(Browser.navigator ?? TestNavigator());

  static final List<Browser> _knownBrowsers = [
    internetExplorer,
    firefox,
    safari,
    wkWebView,
    edgeChrome,
    chrome
  ];

  bool get isChrome => this == chrome || this == edgeChrome;

  /// Whether the browser is [edgeChrome].
  bool get isEdgeChrome => this == edgeChrome;
  bool get isFirefox => this == firefox;
  bool get isSafari => this == safari;
  bool get isInternetExplorer => this == internetExplorer;
  bool get isWKWebView => this == wkWebView;
}

Browser chrome = _Chrome();
Browser firefox = _Firefox();
Browser safari = _Safari();
Browser internetExplorer = _InternetExplorer();
Browser wkWebView = _WKWebView();

/// The Edge browser from Microsoft that is based on the Blink rendering engine.
///
/// * For the purposes of detecting capabilities / features - this browser should
/// be treated as a Blink/Chrome browser.
///   *(Truthy for both [Browser.isChrome] and [Browser.isEdgeChrome])*
/// * For the purposes of system logging, it should be detected as a standalone
/// product with its own version.
///
/// > **NOTE** In addition to the Edge `version`, the underlying Blink engine
/// version can be accessed via `chromeVersion`.
EdgeChrome edgeChrome = EdgeChrome._();

class _Chrome extends Browser {
  _Chrome() : super('Chrome', _isChrome, _getVersion);

  static bool _isChrome(NavigatorProvider navigator) =>
      navigator.vendor.contains('Google');

  static Version _getVersion(NavigatorProvider navigator,
      {String namePrefix = 'Chrome'}) {
    Match? match = RegExp(namePrefix + r"/(\d+)\.(\d+)\.(\d+)\.(\d+)")
        .firstMatch(navigator.appVersion);
    if (match != null) {
      var major = int.parse(match.group(1)!);
      var minor = int.parse(match.group(2)!);
      var patch = int.parse(match.group(3)!);
      var build = match.group(4);
      return Version(major, minor, patch, build: build);
    } else {
      return Version(0, 0, 0);
    }
  }
}

/// See: [edgeChrome]
@visibleForTesting
@internal
class EdgeChrome extends Browser {
  EdgeChrome._()
      : super(
          // name should be `Edge` (essentially for logging purposes only)
          'Edge',
          _isEdge,
          _getVersion,
          // className should remain chrome since the rendering engine is the same
          className: 'chrome',
        );

  /// See: <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/User-Agent#microsoft_edge_ua_string>
  static bool _isEdge(NavigatorProvider navigator) =>
      navigator.userAgent.contains('Edg/');

  static Version _getVersion(NavigatorProvider navigator) =>
      _Chrome._getVersion(Browser.navigator ?? TestNavigator(),
          namePrefix: 'Edg');

  /// The underlying Blink rendering engine version that this version of Edge uses.
  Version get chromeVersion => _chromeVersion ??=
      _Chrome._getVersion(Browser.navigator ?? TestNavigator());
  Version? _chromeVersion;
}

class _Firefox extends Browser {
  _Firefox() : super('Firefox', _isFirefox, _getVersion);

  static bool _isFirefox(NavigatorProvider navigator) {
    return navigator.userAgent.contains('Firefox');
  }

  static Version _getVersion(NavigatorProvider navigator) {
    Match match = RegExp(r'rv:(\d+)\.(\d+)\)').firstMatch(navigator.userAgent)!;
    var major = int.parse(match.group(1)!);
    var minor = int.parse(match.group(2)!);
    return Version(major, minor, 0);
  }
}

class _Safari extends Browser {
  _Safari() : super('Safari', _isSafari, _getVersion);

  static bool _isSafari(NavigatorProvider navigator) {
    // An web view running in an iOS app does not have a 'Version/X.X.X' string in the appVersion
    var vendor = navigator.vendor;
    return vendor.contains('Apple') && navigator.appVersion.contains('Version');
  }

  static Version _getVersion(NavigatorProvider navigator) {
    Match match = RegExp(r'Version/(\d+)(\.(\d+))?(\.(\d+))?')
        .firstMatch(navigator.appVersion)!;
    var major = int.parse(match.group(1)!);
    var minor = int.parse(match.group(3) ?? '0');
    var patch = int.parse(match.group(5) ?? '0');

    return Version(major, minor, patch);
  }
}

class _WKWebView extends Browser {
  _WKWebView() : super('WKWebView', _isWKWebView, _getVersion);

  static bool _isWKWebView(NavigatorProvider navigator) =>
      // An web view running in an iOS app does not have a 'Version/X.X.X' string in the appVersion
      navigator.vendor.contains('Apple') &&
      !navigator.appVersion.contains('Version');

  static Version _getVersion(NavigatorProvider navigator) {
    Match match = RegExp(r'AppleWebKit/(\d+)\.(\d+)\.(\d+)')
        .firstMatch(navigator.appVersion)!;
    var major = int.parse(match.group(1)!);
    var minor = int.parse(match.group(2)!);
    var patch = int.parse(match.group(3)!);
    return Version(major, minor, patch);
  }
}

class _InternetExplorer extends Browser {
  _InternetExplorer()
      : super('Internet Explorer', _isInternetExplorer, _getVersion,
            className: 'ie');

  static bool _isInternetExplorer(NavigatorProvider navigator) {
    return navigator.appName.contains('Microsoft') ||
        navigator.appVersion.contains('Trident') ||
        navigator.appVersion.contains('Edge');
  }

  static Version _getVersion(NavigatorProvider navigator) {
    Match? match =
        RegExp(r'MSIE (\d+)\.(\d+);').firstMatch(navigator.appVersion);
    if (match != null) {
      var major = int.parse(match.group(1)!);
      var minor = int.parse(match.group(2)!);
      return Version(major, minor, 0);
    }

    match = RegExp(r'rv[: ](\d+)\.(\d+)').firstMatch(navigator.appVersion);
    if (match != null) {
      var major = int.parse(match.group(1)!);
      var minor = int.parse(match.group(2)!);
      return Version(major, minor, 0);
    }

    match = RegExp(r'Edge/(\d+)\.(\d+)$').firstMatch(navigator.appVersion);
    if (match != null) {
      var major = int.parse(match.group(1)!);
      var minor = int.parse(match.group(2)!);
      return Version(major, minor, 0);
    }

    return Version(0, 0, 0);
  }
}

class _HtmlNavigator implements NavigatorProvider {
  @override
  String get vendor => web.window.navigator.vendor;
  @override
  String get appVersion => web.window.navigator.appVersion;
  @override
  String get appName => web.window.navigator.appName;
  @override
  String get userAgent => web.window.navigator.userAgent;
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
