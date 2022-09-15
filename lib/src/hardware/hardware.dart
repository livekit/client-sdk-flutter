import 'dart:async';

import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;

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
          devices.where((element) => element.kind == 'audioinput').first;
      selectedAudioOutput ??=
          devices.where((element) => element.kind == 'audiooutput').first;
      selectedVideoInput ??=
          devices.where((element) => element.kind == 'videoinput').first;
    });
  }

  static final Hardware instance = Hardware._internal();

  final StreamController<List<MediaDevice>> onDeviceChange =
      StreamController.broadcast();

  MediaDevice? selectedAudioInput;

  MediaDevice? selectedAudioOutput;

  MediaDevice? selectedVideoInput;

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
    if (rtc.WebRTC.platformIsWeb) {
      throw UnimplementedError('selectAudioOutput not support on web');
    }
    selectedAudioOutput = device;
    await rtc.Helper.selectAudioOutput(device.deviceId);
  }

  Future<void> selectAudioInput(MediaDevice device) async {
    if (rtc.WebRTC.platformIsWeb || rtc.WebRTC.platformIsIOS) {
      throw UnimplementedError(
          'selectAudioInput is only supported on Android/Windows/macOS');
    }
    selectedAudioInput = device;
    await rtc.Helper.selectAudioInput(device.deviceId);
  }

  Future<void> setSpeakerphoneOn(bool enable) async {
    if (rtc.WebRTC.platformIsMobile) {
      await rtc.Helper.setSpeakerphoneOn(enable);
    } else {
      throw UnimplementedError('setSpeakerphoneOn only support on iOS/Android');
    }
  }

  Future<rtc.MediaStream> openCamera(
      {MediaDevice? device, bool? facingMode}) async {
    var constraints = <String, dynamic>{
      if (facingMode != null) 'facingMode': facingMode ? 'user' : 'environment',
    };
    if (device != null) {
      if (rtc.WebRTC.platformIsWeb) {
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
        devices.where((element) => element.kind == 'audioinput').first;
    selectedAudioOutput ??=
        devices.where((element) => element.kind == 'audiooutput').first;
    selectedVideoInput ??=
        devices.where((element) => element.kind == 'videoinput').first;
    onDeviceChange.add(devices);
  }
}
