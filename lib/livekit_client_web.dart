import 'dart:async';

import 'package:flutter/services.dart';

import 'package:flutter_web_plugins/flutter_web_plugins.dart';

// In order to *not* need this ignore, consider extracting the "web" version
// of your plugin as a separate package, instead of inlining it in the same
// package as the core of your plugin.
// ignore: avoid_web_libraries_in_flutter
// import 'dart:html' as html show window;

/// A web implementation of the Livekit plugin.
class LiveKitWebPlugin {
  static void registerWith(Registrar registrar) {
    final MethodChannel channel = MethodChannel(
      'livekit_client',
      const StandardMethodCodec(),
      registrar,
    );

    final pluginInstance = LiveKitWebPlugin();
    channel.setMethodCallHandler(pluginInstance.handleMethodCall);
  }

  /// Handles method calls over the MethodChannel of this plugin.
  /// Note: Check the "federated" architecture for a new way of doing this:
  /// https://flutter.dev/go/federated-plugins
  Future<dynamic> handleMethodCall(MethodCall call) async {
    // no-op for now
    throw PlatformException(
      code: 'Unimplemented',
      details: 'livekit for web doesn\'t implement \'${call.method}\'',
    );
  }
}
