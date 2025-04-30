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

import 'package:flutter/services.dart';

import 'package:meta/meta.dart';

import '../logger.dart';
import '../managers/broadcast_manager.dart';
import 'native_audio.dart';

// Method channel methods to call native code.
class Native {
  @internal
  static final channel = _createChannel();

  static MethodChannel _createChannel() {
    final channel = MethodChannel('livekit_client');
    channel.setMethodCallHandler(_handleMethodCall);
    return channel;
  }

  @internal
  static bool bypassVoiceProcessing = false;

  @internal
  static Future<bool> configureAudio(
      NativeAudioConfiguration configuration) async {
    try {
      final result = await channel.invokeMethod<bool>(
        'configureNativeAudio',
        configuration.toMap(),
      );
      return result == true;
    } catch (error) {
      logger.warning('configureNativeAudio did throw $error');
      return false;
    }
  }

  @internal
  static Future<bool> startVisualizer(
    String trackId, {
    bool isCentered = true,
    int barCount = 7,
    String visualizerId = '',
    bool smoothTransition = true,
  }) async {
    try {
      final result = await channel.invokeMethod<bool>(
        'startVisualizer',
        <String, dynamic>{
          'trackId': trackId,
          'isCentered': isCentered,
          'barCount': barCount,
          'visualizerId': visualizerId,
          'smoothTransition': smoothTransition,
        },
      );
      return result == true;
    } catch (error) {
      logger.warning('startVisualizer did throw $error');
      return false;
    }
  }

  @internal
  static Future<void> stopVisualizer(String trackId,
      {required String visualizerId}) async {
    try {
      await channel.invokeMethod<void>(
        'stopVisualizer',
        <String, dynamic>{
          'trackId': trackId,
          'visualizerId': visualizerId,
        },
      );
    } catch (error) {
      logger.warning('stopVisualizer did throw $error');
    }
  }

  /// Returns OS's version as a string
  /// Currently only for iOS, macOS
  @internal
  static Future<String?> osVersionString() async {
    try {
      return await channel.invokeMethod<String>(
        'osVersionString',
        <String, dynamic>{},
      );
    } catch (error) {
      logger.warning('appleOSVersionString did throw error: ${error}');
    }
    return null;
  }

  static Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'broadcastStateChanged':
        if (call.arguments is! bool) {
          logger.warning('broadcastStateChanged did not receive bool');
          return null;
        }
        _broadcastStateChanged(call.arguments as bool);
        return null;
      default:
        logger.warning('Method ${call.method} is not implemented.');
        return null;
    }
  }

  static void _broadcastStateChanged(bool isBroadcasting) {
    BroadcastManager().broadcastStateChanged(isBroadcasting);
  }

  @internal
  static void broadcastRequestActivation() {
    try {
      channel.invokeMethod('broadcastRequestActivation', <String, dynamic>{});
    } catch (error) {
      logger.warning('broadcastRequestActivation did throw error: ${error}');
    }
  }

  @internal
  static void broadcastRequestStop() {
    try {
      channel.invokeMethod('broadcastRequestStop', <String, dynamic>{});
    } catch (error) {
      logger.warning('broadcastRequestStop did throw error: ${error}');
    }
  }
}

// Initialize the channel before first reference so method calls can be handled.
// ignore: unused_element
final _channelInitializer = Native.channel;
