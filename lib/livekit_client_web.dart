import 'dart:async';

import 'package:flutter/services.dart';

import 'package:flutter_web_plugins/flutter_web_plugins.dart';

// In order to *not* need this ignore, consider extracting the "web" version
// of your plugin as a separate package, instead of inlining it in the same
// package as the core of your plugin.

// ignore: unused_import
import 'dart:html' as html show document, ScriptElement; // import_sorter: keep

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

    // Unofficial method load js as flutter assets (unreliable)
    // html.document.head!.append(html.ScriptElement()
    //   ..src = 'assets/packages/livekit_client/assets/ua-parser.min.js'
    //   ..type = 'application/javascript'
    //   ..defer = true
    //   );
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
