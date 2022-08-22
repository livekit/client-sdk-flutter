// ignore_for_file: must_be_immutable

import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../theme.dart';

class SettingsDialog extends Dialog {
  SettingsDialog({Key? key}) : super(key: key) {
    _localRenderer = RTCVideoRenderer();
    _localRenderer?.initialize().then((_) async {
      _mediaDevicesList = await Hardware.instance.enumerateDevices();
      _cameraStream = await Hardware.instance.openCamera();
      if (_stateSetter != null) {
        _stateSetter!(() {
          _localRenderer!.srcObject = _cameraStream;
        });
      }
    });
  }

  StateSetter? _stateSetter;
  List<MediaDevice>? _mediaDevicesList;
  RTCVideoRenderer? _localRenderer;
  MediaStream? _cameraStream;

  void cleanup() {
    if (_localRenderer != null) {
      _localRenderer?.srcObject = null;
      _localRenderer?.dispose();
      _localRenderer = null;
    }

    if (_cameraStream != null) {
      for (var track in _cameraStream!.getTracks()) {
        track.stop();
      }
      _cameraStream = null;
    }
  }

  void _ok(BuildContext context) {
    cleanup();
    Navigator.pop<void>(context);
  }

  void _cancel(BuildContext context) {
    cleanup();
    Navigator.pop<void>(context);
  }

  String? _selectedAudioOutput;
  String? _selectedAudioInput;
  String? _selectedVideoInput;

  String get audioOutput {
    return _selectedAudioOutput ?? 'default';
  }

  String get audioInput {
    return _selectedAudioInput ?? 'default';
  }

  String get videoInput {
    return _selectedVideoInput ??
        _mediaDevicesList?.firstWhere((d) => d.kind == 'videoinput').deviceId ??
        '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
          child: Container(
        width: 580,
        height: 540,
        color: LKColors.lkDarkBlue,
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(10),
              child: Stack(
                children: <Widget>[
                  const Align(
                    alignment: Alignment.topLeft,
                    child: Text(
                      'Hardware Settings',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                  Align(
                    alignment: Alignment.topRight,
                    child: InkWell(
                      child: const Icon(Icons.close),
                      onTap: () => _cancel(context),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
                flex: 1,
                child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(24, 0, 10, 24),
                    child: StatefulBuilder(builder: (context, setState) {
                      _stateSetter = setState;
                      return Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Video Inputs:',
                              style: TextStyle(
                                  color: Colors.white, fontSize: 16.0),
                            ),
                            const Text(
                              'Choose the camera you use in the meeting',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 12.0),
                            ),
                            DropdownButton<String>(
                              value: videoInput,
                              onChanged: (val) =>
                                  setState(() => _selectedVideoInput = val),
                              items: _mediaDevicesList != null
                                  ? _mediaDevicesList!
                                      .where((device) =>
                                          device.kind == 'videoinput')
                                      .map((device) {
                                      return DropdownMenuItem<String>(
                                        value: device.deviceId,
                                        child: Text(device.label),
                                      );
                                    }).toList()
                                  : [],
                            ),
                            SizedBox(
                              width: 200,
                              height: 140,
                              child: RTCVideoView(
                                _localRenderer!,
                                mirror: true,
                              ),
                            ),
                            const Text(
                              'Audio Inputs:',
                              style: TextStyle(
                                  color: Colors.white, fontSize: 16.0),
                            ),
                            const Text(
                              'Choose the microphone or audio input device.',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 12.0),
                            ),
                            DropdownButton<String>(
                              value: audioInput,
                              onChanged: (val) =>
                                  setState(() => _selectedAudioInput = val),
                              items: _mediaDevicesList != null
                                  ? _mediaDevicesList!
                                      .where((device) =>
                                          device.kind == 'audioinput')
                                      .map((device) {
                                      return DropdownMenuItem<String>(
                                        value: device.deviceId,
                                        child: Text(device.label),
                                      );
                                    }).toList()
                                  : [],
                            ),
                            const Text(
                              'Audio Outputs:',
                              style: TextStyle(
                                  color: Colors.white, fontSize: 16.0),
                            ),
                            const Text(
                              'Choose the audio output device.',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 12.0),
                            ),
                            DropdownButton<String>(
                              value: audioOutput,
                              onChanged: (val) =>
                                  setState(() => _selectedAudioOutput = val),
                              items: _mediaDevicesList != null
                                  ? _mediaDevicesList!
                                      .where((device) =>
                                          device.kind == 'audiooutput')
                                      .map((device) {
                                      return DropdownMenuItem<String>(
                                        value: device.deviceId,
                                        child: Text(device.label),
                                      );
                                    }).toList()
                                  : [],
                            ),
                          ]);
                    }))),
            SizedBox(
              width: double.infinity,
              child: ButtonBar(
                children: <Widget>[
                  MaterialButton(
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.white),
                    ),
                    onPressed: () {
                      _cancel(context);
                    },
                  ),
                  MaterialButton(
                    color: Theme.of(context).primaryColor,
                    child: const Text(
                      'Ok',
                      style: TextStyle(color: Colors.white),
                    ),
                    onPressed: () {
                      _ok(context);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      )),
    );
  }
}
