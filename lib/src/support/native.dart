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

import 'dart:async';

import 'package:flutter/services.dart' show MethodChannel, MethodCall, MissingPluginException, PlatformException;

import 'package:meta/meta.dart';

import '../audio/audio_manager.dart';
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

  /// Configures (and caches) the Apple audio session.
  ///
  /// When [automatic] is true, the native audio-engine delegate owns activation
  /// timing: the configuration is cached and (re)applied on engine lifecycle
  /// events, and only applied immediately here if the engine is already
  /// running. When false (manual mode / explicit apply) it is applied
  /// immediately.
  @internal
  static Future<bool> configureAudio(
    NativeAudioConfiguration configuration, {
    bool automatic = false,
    bool selectCategoryByEngineState = false,
    bool forceSpeakerOutput = false,
  }) async {
    try {
      final result = await channel.invokeMethod<bool>(
        'configureNativeAudio',
        <String, dynamic>{
          ...configuration.toMap(),
          'automatic': automatic,
          'selectCategoryByEngineState': selectCategoryByEngineState,
          'forceSpeakerOutput': forceSpeakerOutput,
        },
      );
      return result == true;
    } catch (error) {
      logger.warning('configureNativeAudio did throw $error');
      return false;
    }
  }

  /// Applies runtime audio processing options to a local audio track.
  ///
  /// Resolved natively against the underlying WebRTC audio track owned by
  /// flutter_webrtc; [options] is the serialized [AudioProcessingOptions] map.
  /// Returns the native result map (`result`/`code`/`message`) so the Dart
  /// track API can translate native outcomes into typed exceptions.
  /// This plugin is registered on platforms that do not implement runtime audio
  /// processing, so missing or explicitly unimplemented hooks are normalized to
  /// `rejectedPlatformUnavailable`. Other channel errors propagate because they
  /// indicate unexpected native failures rather than an unsupported platform
  /// capability.
  @internal
  static Future<Map<String, dynamic>> setAudioProcessingOptions(
    String trackId,
    Map<String, dynamic> options,
  ) async {
    try {
      final response = await channel.invokeMethod<dynamic>(
        'setAudioProcessingOptions',
        <String, dynamic>{
          'trackId': trackId,
          ...options,
        },
      );
      if (response is Map) {
        return response.map((key, value) => MapEntry(key.toString(), value));
      }
      return <String, dynamic>{};
    } on MissingPluginException {
      return _audioProcessingPlatformUnavailable();
    } on PlatformException catch (error) {
      // Web registers the plugin but returns `Unimplemented` for methods it
      // does not support. Treat only that narrow case like a missing native
      // implementation; do not hide unrelated native/channel failures.
      if (error.code == 'Unimplemented') {
        return _audioProcessingPlatformUnavailable();
      }
      rethrow;
    }
  }

  static Map<String, dynamic> _audioProcessingPlatformUnavailable() => <String, dynamic>{
        'result': false,
        'code': 'rejectedPlatformUnavailable',
        'message': 'Audio processing options are unavailable on this platform.',
      };

  static PlatformException _audioProcessingPlatformUnavailableException() => PlatformException(
        code: 'rejectedPlatformUnavailable',
        message: 'Audio processing options are unavailable on this platform.',
      );

  /// Starts the native WebRTC audio device module recording path with the
  /// capture-time audio processing options for the local microphone track.
  @internal
  static Future<void> startLocalRecording(Map<String, dynamic> audioProcessingOptions) async {
    try {
      await channel.invokeMethod<void>(
        'startLocalRecording',
        audioProcessingOptions,
      );
    } on PlatformException catch (error) {
      if (error.code == 'Unimplemented') {
        throw _audioProcessingPlatformUnavailableException();
      }
      rethrow;
    } on MissingPluginException {
      throw _audioProcessingPlatformUnavailableException();
    }
  }

  /// Stops recording that was explicitly started through [startLocalRecording].
  @internal
  static Future<void> stopLocalRecording() async {
    try {
      await channel.invokeMethod<void>('stopLocalRecording', <String, dynamic>{});
    } on PlatformException catch (error) {
      if (error.code == 'Unimplemented') {
        logger.warning('stopLocalRecording is not implemented on this platform');
        return;
      }
      logger.warning('stopLocalRecording did throw ${error.code}: ${error.message}');
    } on MissingPluginException {
      logger.warning('stopLocalRecording is not available on this platform');
    }
  }

  /// Reads the engine-wide audio processing state from the native peer
  /// connection factory. Returns `null` when unavailable (e.g. the factory
  /// does not exist yet, or the platform cannot provide it).
  @internal
  static Future<Map<String, dynamic>?> getAudioProcessingState() async {
    try {
      final response = await channel.invokeMethod<dynamic>(
        'getAudioProcessingState',
        <String, dynamic>{},
      );
      if (response is Map) {
        return response.map((key, value) => MapEntry(key.toString(), value));
      }
    } catch (error) {
      logger.warning('getAudioProcessingState did throw $error');
    }
    return null;
  }

  /// Configure and activate LiveKit's Android audio session (mode/focus/routing).
  @internal
  static Future<void> configureAndroidAudioSession(Map<String, dynamic> configuration) async {
    try {
      await channel.invokeMethod<void>('configureAndroidAudioSession', configuration);
    } catch (error) {
      logger.warning('configureAndroidAudioSession did throw $error');
    }
  }

  /// Deactivate LiveKit's Android audio session (release focus, restore mode).
  @internal
  static Future<void> stopAndroidAudioSession() async {
    try {
      await channel.invokeMethod<void>('stopAndroidAudioSession');
    } catch (error) {
      logger.warning('stopAndroidAudioSession did throw $error');
    }
  }

  /// Deactivate LiveKit's Apple audio session.
  @internal
  static Future<void> deactivateAppleAudioSession() async {
    try {
      await channel.invokeMethod<void>('deactivateAppleAudioSession', <String, dynamic>{});
    } catch (error) {
      logger.warning('deactivateAppleAudioSession did throw $error');
    }
  }

  /// Route Android audio output to/from the speakerphone.
  @internal
  static Future<void> setAndroidSpeakerphoneOn(bool enable, {bool force = false}) async {
    try {
      await channel.invokeMethod<void>(
        'setAndroidSpeakerphoneOn',
        <String, dynamic>{'enable': enable, 'force': force},
      );
    } catch (error) {
      logger.warning('setAndroidSpeakerphoneOn did throw $error');
    }
  }

  /// Enable or disable LiveKit's automatic iOS audio-session management from
  /// native WebRTC audio-engine lifecycle callbacks.
  @internal
  static Future<void> setAppleAudioSessionAutomaticManagementEnabled(bool enabled) async {
    try {
      await channel.invokeMethod<void>(
        'setAppleAudioSessionAutomaticManagementEnabled',
        <String, dynamic>{'enabled': enabled},
      );
    } catch (error) {
      logger.warning('setAppleAudioSessionAutomaticManagementEnabled did throw $error');
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
  static Future<void> stopVisualizer(String trackId, {required String visualizerId}) async {
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

  @internal
  static Future<bool> startAudioRenderer({
    required String trackId,
    required String rendererId,
    required Map<String, dynamic> format,
  }) async {
    try {
      final result = await channel.invokeMethod<bool>(
        'startAudioRenderer',
        <String, dynamic>{
          'trackId': trackId,
          'rendererId': rendererId,
          'format': format,
        },
      );
      return result == true;
    } catch (error) {
      logger.warning('startAudioRenderer did throw $error');
      return false;
    }
  }

  @internal
  static Future<void> stopAudioRenderer({
    required String rendererId,
  }) async {
    try {
      await channel.invokeMethod<void>(
        'stopAudioRenderer',
        <String, dynamic>{
          'rendererId': rendererId,
        },
      );
    } catch (error) {
      logger.warning('stopAudioRenderer did throw $error');
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
      case 'onAudioEngineState':
        final args = call.arguments;
        if (args is Map) {
          AudioManager.instance.handleAudioEngineState(
            isPlayoutEnabled: args['isPlayoutEnabled'] == true,
            isRecordingEnabled: args['isRecordingEnabled'] == true,
          );
        }
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
  static Future<void> broadcastRequestActivation() async {
    try {
      await channel.invokeMethod('broadcastRequestActivation', <String, dynamic>{});
    } catch (error) {
      logger.warning('broadcastRequestActivation did throw error: ${error}');
    }
  }

  @internal
  static Future<void> broadcastRequestStop() async {
    try {
      await channel.invokeMethod('broadcastRequestStop', <String, dynamic>{});
    } catch (error) {
      logger.warning('broadcastRequestStop did throw error: ${error}');
    }
  }
}

// Initialize the channel before first reference so method calls can be handled.
// ignore: unused_element
final _channelInitializer = Native.channel;
