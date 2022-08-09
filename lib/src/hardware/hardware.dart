import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;

class MediaDevice {
  MediaDevice(this.deviceId, this.label, this.kind);

  final String deviceId;
  final String label;
  final String kind;

  @override
  String toString() {
    return 'MediaDevice{deviceId: $deviceId, label: $label, kind: $kind}';
  }
}

// Help create a hardware setup dialog, or switch audio and video devices during a call
class Hardware {
  static Future<List<dynamic>> audioInputs() async {
    return enumerateDevices('audioinput');
  }

  static Future<List<dynamic>> audioOutputs() async {
    return enumerateDevices('audiooutput');
  }

  static Future<List<dynamic>> videoInputs() async {
    return enumerateDevices('videoinput');
  }

  static Future<void> selectAudioOutput(MediaDevice device) async {
    // TODO(duan): implement
  }

  static Future<void> selectAudioInput(MediaDevice device) async {
    await rtc.navigator.mediaDevices
        .selectAudioOutput(rtc.AudioOutputOptions(deviceId: device.deviceId));
  }

  static Future<rtc.MediaStream> openCamera(
      {MediaDevice? device, bool front = true}) async {
    var constraints = <String, dynamic>{
      'facingMode': front ? 'user' : 'environment',
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
    return rtc.navigator.mediaDevices.getUserMedia(<String, dynamic>{
      'audio': false,
      'viddeo': device != null ? constraints : true,
    });
  }

  static Future<List<MediaDevice>> enumerateDevices(String type) async {
    var devices = await rtc.navigator.mediaDevices.enumerateDevices();
    return devices
        .where((d) => d.kind == type)
        .map((e) => MediaDevice(e.deviceId, e.label, e.kind!))
        .toList();
  }
}
