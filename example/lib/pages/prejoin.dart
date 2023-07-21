import 'dart:async';

import 'package:dropdown_textfield/dropdown_textfield.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:livekit_example/exts.dart';
import 'package:random_name_generator/random_name_generator.dart';

import '../widgets/text_field.dart';
import 'room.dart';

class PreJoinPage extends StatefulWidget {
  const PreJoinPage(
    this.url,
    this.token, {
    Key? key,
    this.e2ee = false,
    this.e2eeKey,
    this.simulcast = true,
    this.adaptiveStream = true,
    this.dynacast = true,
  }) : super(key: key);
  final String url;
  final String token;
  final bool e2ee;
  final String? e2eeKey;
  final bool simulcast;
  final bool adaptiveStream;
  final bool dynacast;
  @override
  State<StatefulWidget> createState() => _PreJoinPageState();
}

class _PreJoinPageState extends State<PreJoinPage> {
  final _displayNameCtrl = TextEditingController();
  List<MediaDevice> _audioInputs = [];
  List<MediaDevice> _videoInputs = [];
  StreamSubscription? _subscription;
  var _selectedAudioIdx = 0;
  var _selectedVideoIdx = 0;
  bool _busy = false;
  bool _enableVideo = true;
  bool _enableAudio = true;
  LocalAudioTrack? _audioTrack;
  LocalVideoTrack? _videoTrack;

  @override
  void initState() {
    super.initState();
    _subscription = Hardware.instance.onDeviceChange.stream
        .listen((List<MediaDevice> devices) {
      _loadDevices(devices);
    });
    Hardware.instance.enumerateDevices().then(_loadDevices);
    var randomNames = RandomNames(Zone.us);
    _displayNameCtrl.text = randomNames.name();
  }

  void _loadDevices(List<MediaDevice> devices) async {
    _audioInputs = devices.where((d) => d.kind == 'audioinput').toList();
    _videoInputs = devices.where((d) => d.kind == 'videoinput').toList();
    setState(() {});
    await _changeLocalVideoTrack();
    await _changeLocalAudioTrack();
  }

  void _setEnableVideo(value) {
    _enableVideo = value;
    setState(() {});
  }

  void _setEnableAudio(value) {
    _enableAudio = value;
    setState(() {});
  }

  Future<void> _changeLocalAudioTrack() async {
    if (_audioTrack != null) {
      await _audioTrack!.stop();
      _audioTrack = null;
    }
    var audioInput = _audioInputs.isNotEmpty
        ? _audioInputs[_selectedAudioIdx].deviceId
        : null;

    if (audioInput != null) {
      _audioTrack = await LocalAudioTrack.create(AudioCaptureOptions(
        deviceId: audioInput,
      ));
    }
    setState(() {});
  }

  Future<void> _changeLocalVideoTrack() async {
    if (_videoTrack != null) {
      await _videoTrack!.stop();
      _videoTrack = null;
    }
    var videoInput = _videoInputs.isNotEmpty
        ? _videoInputs[_selectedVideoIdx].deviceId
        : null;

    if (videoInput != null) {
      _videoTrack =
          await LocalVideoTrack.createCameraTrack(CameraCaptureOptions(
        deviceId: videoInput,
      ));
    }
    setState(() {});
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  _join(BuildContext context) async {
    var videoInput = _videoInputs.isNotEmpty
        ? _videoInputs[_selectedVideoIdx].deviceId
        : null;
    var audioInput = _audioInputs.isNotEmpty
        ? _audioInputs[_selectedAudioIdx].deviceId
        : null;
    var displayName = _displayNameCtrl.text;
    if (displayName.isEmpty) {
      displayName = RandomNames(Zone.us).name();
    }
    _busy = true;
    print('Joining with $videoInput, $audioInput, $displayName');

    try {
      //create new room
      final room = Room();

      // Create a Listener before connecting
      final listener = room.createListener();

      E2EEOptions? e2eeOptions;
      if (widget.e2ee && widget.e2eeKey != null) {
        final keyProvider = await BaseKeyProvider.create();
        e2eeOptions = E2EEOptions(keyProvider: keyProvider);
        await keyProvider.setKey(widget.e2eeKey!);
      }

      // Try to connect to the room
      // This will throw an Exception if it fails for any reason.
      await room.connect(
        widget.url,
        widget.token,
        roomOptions: RoomOptions(
          adaptiveStream: widget.adaptiveStream,
          dynacast: widget.dynacast,
          defaultAudioPublishOptions:
              const AudioPublishOptions(name: 'custom_audio_track_name'),
          defaultVideoPublishOptions: VideoPublishOptions(
            simulcast: widget.simulcast,
          ),
          defaultScreenShareCaptureOptions: const ScreenShareCaptureOptions(
              useiOSBroadcastExtension: true,
              params: VideoParameters(
                  dimensions: VideoDimensionsPresets.h1080_169,
                  encoding: VideoEncoding(
                    maxBitrate: 3 * 1000 * 1000,
                    maxFramerate: 15,
                  ))),
          defaultCameraCaptureOptions: const CameraCaptureOptions(
              maxFrameRate: 30,
              params: VideoParameters(
                  dimensions: VideoDimensionsPresets.h720_169,
                  encoding: VideoEncoding(
                    maxBitrate: 2 * 1000 * 1000,
                    maxFramerate: 30,
                  ))),
          e2eeOptions: e2eeOptions,
        ),
        fastConnectOptions: FastConnectOptions(
          microphone: TrackOption(enabled: _enableAudio, track: _audioTrack),
          camera: TrackOption(enabled: _enableVideo, track: _videoTrack),
        ),
      );

      await Navigator.push<void>(
        context,
        MaterialPageRoute(builder: (_) => RoomPage(room, listener)),
      );
    } catch (error) {
      print('Could not connect $error');
      await context.showErrorDialog(error);
    } finally {
      setState(() {
        _busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Select Devices'),
        ),
        body: Container(
            alignment: Alignment.center,
            child: SingleChildScrollView(
                child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 20,
              ),
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: SizedBox(
                          width: 320,
                          height: 240,
                          child: _videoTrack != null
                              ? VideoTrackRenderer(
                                  _videoTrack!,
                                  fit: RTCVideoViewObjectFit
                                      .RTCVideoViewObjectFitContain,
                                )
                              : const Placeholder(),
                        )),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Camera:'),
                          Switch(
                            value: _enableVideo,
                            onChanged: (value) => _setEnableVideo(value),
                          ),
                        ],
                      ),
                    ),
                    if (_enableVideo)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 25),
                        child: DropDownTextField(
                          initialValue: 'Please select a camera',
                          listSpace: 20,
                          listPadding: ListPadding(top: 20),
                          enableSearch: false,
                          validator: (value) {
                            if (value == null) {
                              return 'Required field';
                            } else {
                              return null;
                            }
                          },
                          dropDownList: _videoInputs
                              .map((e) => DropDownValueModel(
                                  name: e.label, value: e.deviceId))
                              .toList(),
                          listTextStyle: const TextStyle(color: Colors.white),
                          dropDownItemCount: _videoInputs.length,
                          dropDownIconProperty: IconProperty(
                            color: Colors.white,
                          ),
                          onChanged: (val) {
                            print('onChanged $val');
                            if (val != null) {
                              _selectedVideoIdx = _videoInputs.indexWhere(
                                  (element) => val.value == element.deviceId);
                              _changeLocalVideoTrack();
                            }
                          },
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Micriphone:'),
                          Switch(
                            value: _enableAudio,
                            onChanged: (value) => _setEnableAudio(value),
                          ),
                        ],
                      ),
                    ),
                    if (_enableAudio)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 25),
                        child: DropDownTextField(
                          initialValue: 'Please select a microphone',
                          listSpace: 20,
                          listPadding: ListPadding(top: 20),
                          enableSearch: false,
                          validator: (value) {
                            if (value == null) {
                              return 'Required field';
                            } else {
                              return null;
                            }
                          },
                          dropDownList: _audioInputs
                              .map((e) => DropDownValueModel(
                                  name: e.label, value: e.deviceId))
                              .toList(),
                          listTextStyle: const TextStyle(color: Colors.white),
                          dropDownItemCount: _audioInputs.length,
                          dropDownIconProperty: IconProperty(
                            color: Colors.white,
                          ),
                          onChanged: (val) {
                            print('onChanged $val');
                            if (val != null) {
                              _selectedAudioIdx = _audioInputs.indexWhere(
                                  (element) => val.value == element.deviceId);
                              _changeLocalAudioTrack();
                            }
                          },
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 25),
                      child: LKTextField(
                        label: 'Display Name',
                        ctrl: _displayNameCtrl,
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _busy ? null : () => _join(context),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_busy)
                            const Padding(
                              padding: EdgeInsets.only(right: 10),
                              child: SizedBox(
                                height: 15,
                                width: 15,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                          const Text('JOIN'),
                        ],
                      ),
                    ),
                  ]),
            ))));
  }
}
