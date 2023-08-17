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

import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;

import '../logger.dart';
import '../support/native.dart';
import '../support/native_audio.dart';
import '../support/platform.dart';
import '../track/audio_management.dart';

class MediaDevice {
  const MediaDevice(this.deviceId, this.label, this.kind);

  final String deviceId;
  final String label;
  final String kind;

  @override
  bool operator ==(covariant MediaDevice other) {
    if (identical(this, other)) return true;

    return other.deviceId == deviceId &&
        other.kind == kind &&
        other.label == label;
  }

  @override
  int get hashCode {
    return deviceId.hashCode ^ kind.hashCode ^ label.hashCode;
  }

  @override
  String toString() {
    return 'MediaDevice{deviceId: $deviceId, label: $label, kind: $kind}';
  }
}

class Hardware {
  Hardware._internal() {
    rtc.navigator.mediaDevices.ondevicechange = _onDeviceChange;
    enumerateDevices().then((devices) {
      selectedAudioInput ??=
          devices.firstWhereOrNull((element) => element.kind == 'audioinput');
      selectedAudioOutput ??=
          devices.firstWhereOrNull((element) => element.kind == 'audiooutput');
      selectedVideoInput ??=
          devices.firstWhereOrNull((element) => element.kind == 'videoinput');
      speakerOn = true;
    });
  }

  static final Hardware instance = Hardware._internal();

  final StreamController<List<MediaDevice>> onDeviceChange =
      StreamController.broadcast();

  MediaDevice? selectedAudioInput;

  MediaDevice? selectedAudioOutput;

  MediaDevice? selectedVideoInput;

  bool? speakerOn;

  bool _preferSpeakerOutput = false;

  Future<List<MediaDevice>> enumerateDevices({String? type}) async {
    var infos = await rtc.navigator.mediaDevices.enumerateDevices();
    var devices =
        infos.map((e) => MediaDevice(e.deviceId, e.label, e.kind!)).toList();
    if (type != null && type.isNotEmpty) {
      devices = devices.where((d) => d.kind == type).toList();
    }
    return devices;
  }

  Future<List<MediaDevice>> audioInputs() async {
    return enumerateDevices(type: 'audioinput');
  }

  Future<List<MediaDevice>> audioOutputs() async {
    return enumerateDevices(type: 'audiooutput');
  }

  Future<List<MediaDevice>> videoInputs() async {
    return enumerateDevices(type: 'videoinput');
  }

  Future<void> selectAudioOutput(MediaDevice device) async {
    if (lkPlatformIs(PlatformType.web)) {
      logger.warning('selectAudioOutput not support on web');
      return;
    }
    selectedAudioOutput = device;
    await rtc.Helper.selectAudioOutput(device.deviceId);
  }

  Future<void> selectAudioInput(MediaDevice device) async {
    if (lkPlatformIs(PlatformType.web)) {
      logger.warning(
          'selectAudioInput is only supported on Android/Windows/macOS');
      return;
    }
    selectedAudioInput = device;
    await rtc.Helper.selectAudioInput(device.deviceId);
  }

  Future<void> setPreferSpeakerOutput(bool enable) async {
    if (lkPlatformIsMobile()) {
      if (_preferSpeakerOutput != enable) {
        NativeAudioConfiguration? config;
        if (lkPlatformIs(PlatformType.iOS)) {
          // Only iOS for now...
          config = await onConfigureNativeAudio.call(audioTrackState);
          logger.fine('configuring for ${audioTrackState} using ${config}...');
          try {
            await Native.configureAudio(config);
          } catch (error) {
            logger.warning('failed to configure ${error}');
          }
        }
      }
      _preferSpeakerOutput = enable;
    } else {
      logger.warning('setPreferSpeakerOutput only support on iOS/Android');
    }
  }

  bool get preferSpeakerOutput => _preferSpeakerOutput;

  bool get canSwitchSpeakerphone =>
      lkPlatformIs(PlatformType.iOS) &&
      !_preferSpeakerOutput &&
      [AudioTrackState.localOnly, AudioTrackState.localAndRemote]
          .contains(audioTrackState);

  Future<void> setSpeakerphoneOn(bool enable) async {
    if (lkPlatformIs(PlatformType.iOS)) {
      speakerOn = enable;
      if (canSwitchSpeakerphone) {
        await rtc.Helper.setSpeakerphoneOn(enable);
      } else {
        logger.warning('Can\'t switch speaker/earpiece');
      }
    } else {
      logger.warning('setSpeakerphoneOn only support on iOS');
    }
  }

  Future<rtc.MediaStream> openCamera(
      {MediaDevice? device, bool? facingMode}) async {
    var constraints = <String, dynamic>{
      if (facingMode != null) 'facingMode': facingMode ? 'user' : 'environment',
    };
    if (device != null) {
      if (lkPlatformIs(PlatformType.web)) {
        constraints['deviceId'] = device.deviceId;
      } else {
        constraints['optional'] = [
          {'sourceId': device.deviceId}
        ];
      }
    }
    selectedVideoInput = device;
    return rtc.navigator.mediaDevices.getUserMedia(<String, dynamic>{
      'audio': false,
      'video': device != null ? constraints : true,
    });
  }

  dynamic _onDeviceChange(dynamic _) async {
    var devices = await enumerateDevices();
    selectedAudioInput ??=
        devices.firstWhereOrNull((element) => element.kind == 'audioinput');
    selectedAudioOutput ??=
        devices.firstWhereOrNull((element) => element.kind == 'audiooutput');
    selectedVideoInput ??=
        devices.firstWhereOrNull((element) => element.kind == 'videoinput');
    onDeviceChange.add(devices);
  }
}
