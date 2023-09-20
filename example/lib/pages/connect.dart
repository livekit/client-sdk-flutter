import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:livekit_example/widgets/text_field.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';

import '../exts.dart';
import 'room.dart';

class ConnectPage extends StatefulWidget {
  //
  const ConnectPage({
    Key? key,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ConnectPageState();
}

class _ConnectPageState extends State<ConnectPage> {
  //
  static const _storeKeyUri = 'uri';
  static const _storeKeyToken = 'token';
  static const _storeKeySimulcast = 'simulcast';
  static const _storeKeyAdaptiveStream = 'adaptive-stream';
  static const _storeKeyDynacast = 'dynacast';
  static const _storeKeyFastConnect = 'fast-connect';
  static const _storeKeyE2EE = 'e2ee';
  static const _storeKeySharedKey = 'shared-key';
  static const _storeKeyMultiCodec = 'multi-codec';

  final _uriCtrl = TextEditingController();
  final _tokenCtrl = TextEditingController();
  final _sharedKeyCtrl = TextEditingController();
  bool _simulcast = true;
  bool _adaptiveStream = true;
  bool _dynacast = true;
  bool _busy = false;
  bool _fastConnect = false;
  bool _e2ee = false;
  bool _multiCodec = false;
  String _preferredCodec = 'Preferred Codec';
  String _backupCodec = 'VP8';

  @override
  void initState() {
    super.initState();
    _readPrefs();
    if (lkPlatformIs(PlatformType.android)) {
      _checkPremissions();
    }
  }

  @override
  void dispose() {
    _uriCtrl.dispose();
    _tokenCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkPremissions() async {
    var status = await Permission.bluetooth.request();
    if (status.isPermanentlyDenied) {
      print('Bluetooth Permission disabled');
    }

    status = await Permission.bluetoothConnect.request();
    if (status.isPermanentlyDenied) {
      print('Bluetooth Connect Permission disabled');
    }

    status = await Permission.camera.request();
    if (status.isPermanentlyDenied) {
      print('Camera Permission disabled');
    }

    status = await Permission.microphone.request();
    if (status.isPermanentlyDenied) {
      print('Microphone Permission disabled');
    }
  }

  // Read saved URL and Token
  Future<void> _readPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _uriCtrl.text = const bool.hasEnvironment('URL')
        ? const String.fromEnvironment('URL')
        : prefs.getString(_storeKeyUri) ?? '';
    _tokenCtrl.text = const bool.hasEnvironment('TOKEN')
        ? const String.fromEnvironment('TOKEN')
        : prefs.getString(_storeKeyToken) ?? '';
    _sharedKeyCtrl.text = const bool.hasEnvironment('E2EEKEY')
        ? const String.fromEnvironment('E2EEKEY')
        : prefs.getString(_storeKeySharedKey) ?? '';
    setState(() {
      _simulcast = prefs.getBool(_storeKeySimulcast) ?? true;
      _adaptiveStream = prefs.getBool(_storeKeyAdaptiveStream) ?? true;
      _dynacast = prefs.getBool(_storeKeyDynacast) ?? true;
      _fastConnect = prefs.getBool(_storeKeyFastConnect) ?? false;
      _e2ee = prefs.getBool(_storeKeyE2EE) ?? false;
      _multiCodec = prefs.getBool(_storeKeyMultiCodec) ?? false;
    });
  }

  // Save URL and Token
  Future<void> _writePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storeKeyUri, _uriCtrl.text);
    await prefs.setString(_storeKeyToken, _tokenCtrl.text);
    await prefs.setString(_storeKeySharedKey, _sharedKeyCtrl.text);
    await prefs.setBool(_storeKeySimulcast, _simulcast);
    await prefs.setBool(_storeKeyAdaptiveStream, _adaptiveStream);
    await prefs.setBool(_storeKeyDynacast, _dynacast);
    await prefs.setBool(_storeKeyFastConnect, _fastConnect);
    await prefs.setBool(_storeKeyE2EE, _e2ee);
    await prefs.setBool(_storeKeyMultiCodec, _multiCodec);
  }

  Future<void> _connect(BuildContext ctx) async {
    //
    try {
      setState(() {
        _busy = true;
      });

      // Save URL and Token for convenience
      await _writePrefs();

      print('Connecting with url: ${_uriCtrl.text}, '
          'token: ${_tokenCtrl.text}...');

      E2EEOptions? e2eeOptions;
      if (_e2ee) {
        final keyProvider = await BaseKeyProvider.create();
        e2eeOptions = E2EEOptions(keyProvider: keyProvider);
        var sharedKey = _sharedKeyCtrl.text;
        await keyProvider.setSharedKey(sharedKey);
      }

      String preferredCodec = 'VP8';
      if (_preferredCodec != 'Preferred Codec') {
        preferredCodec = _preferredCodec;
      }

      // create new room
      final room = Room(
          roomOptions: RoomOptions(
        adaptiveStream: _adaptiveStream,
        dynacast: _dynacast,
        defaultAudioPublishOptions: const AudioPublishOptions(
          dtx: true,
        ),
        defaultVideoPublishOptions: VideoPublishOptions(
          simulcast: _simulcast,
          videoCodec: preferredCodec,
        ),
        defaultScreenShareCaptureOptions: const ScreenShareCaptureOptions(
            useiOSBroadcastExtension: true,
            params: VideoParametersPresets.screenShareH1080FPS30),
        e2eeOptions: e2eeOptions,
        defaultCameraCaptureOptions: const CameraCaptureOptions(
          maxFrameRate: 30,
          params: VideoParametersPresets.h720_169,
        ),
      ));

      // Create a Listener before connecting
      final listener = room.createListener();

      // Try to connect to the room
      // This will throw an Exception if it fails for any reason.
      await room.connect(
        _uriCtrl.text,
        _tokenCtrl.text,
        fastConnectOptions: _fastConnect
            ? FastConnectOptions(
                microphone: const TrackOption(enabled: true),
                camera: const TrackOption(enabled: true),
              )
            : null,
      );

      await Navigator.push<void>(
        ctx,
        MaterialPageRoute(builder: (_) => RoomPage(room, listener)),
      );
    } catch (error) {
      print('Could not connect $error');
      await ctx.showErrorDialog(error);
    } finally {
      setState(() {
        _busy = false;
      });
    }
  }

  void _setSimulcast(bool? value) async {
    if (value == null || _simulcast == value) return;
    setState(() {
      _simulcast = value;
    });
  }

  void _setE2EE(bool? value) async {
    if (value == null || _e2ee == value) return;
    setState(() {
      _e2ee = value;
    });
  }

  void _setAdaptiveStream(bool? value) async {
    if (value == null || _adaptiveStream == value) return;
    setState(() {
      _adaptiveStream = value;
    });
  }

  void _setDynacast(bool? value) async {
    if (value == null || _dynacast == value) return;
    setState(() {
      _dynacast = value;
    });
  }

  void _setFastConnect(bool? value) async {
    if (value == null || _fastConnect == value) return;
    setState(() {
      _fastConnect = value;
    });
  }

  void _setMultiCodec(bool? value) async {
    if (value == null || _multiCodec == value) return;
    setState(() {
      _multiCodec = value;
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
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
                    padding: const EdgeInsets.only(bottom: 70),
                    child: SvgPicture.asset(
                      'images/logo-dark.svg',
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 25),
                    child: LKTextField(
                      label: 'Server URL',
                      ctrl: _uriCtrl,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 25),
                    child: LKTextField(
                      label: 'Token',
                      ctrl: _tokenCtrl,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 25),
                    child: LKTextField(
                      label: 'Shared Key',
                      ctrl: _sharedKeyCtrl,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('E2EE'),
                        Switch(
                          value: _e2ee,
                          onChanged: (value) => _setE2EE(value),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Simulcast'),
                        Switch(
                          value: _simulcast,
                          onChanged: (value) => _setSimulcast(value),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Adaptive Stream'),
                        Switch(
                          value: _adaptiveStream,
                          onChanged: (value) => _setAdaptiveStream(value),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Fast Connect'),
                        Switch(
                          value: _fastConnect,
                          onChanged: (value) => _setFastConnect(value),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Dynacast'),
                        Switch(
                          value: _dynacast,
                          onChanged: (value) => _setDynacast(value),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(bottom: _multiCodec ? 5 : 25),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Multi Codec'),
                        Switch(
                          value: _multiCodec,
                          onChanged: (value) => _setMultiCodec(value),
                        ),
                      ],
                    ),
                  ),
                  if (_multiCodec)
                    Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Preferred Codec:'),
                              DropdownButton<String>(
                                value: _preferredCodec,
                                icon: const Icon(
                                  Icons.arrow_drop_down,
                                  color: Colors.blue,
                                ),
                                elevation: 16,
                                style: const TextStyle(color: Colors.blue),
                                underline: Container(
                                  height: 2,
                                  color: Colors.blueAccent,
                                ),
                                onChanged: (String? value) {
                                  // This is called when the user selects an item.
                                  setState(() {
                                    _preferredCodec = value!;
                                  });
                                },
                                items: [
                                  'Preferred Codec',
                                  'AV1',
                                  'VP9',
                                  'VP8',
                                  'H264'
                                ].map<DropdownMenuItem<String>>((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                              )
                            ])),
                  if (_multiCodec &&
                      _preferredCodec != 'Preferred Codec' &&
                      ['av1', 'vp9'].contains(_preferredCodec.toLowerCase()))
                    Padding(
                        padding: const EdgeInsets.only(bottom: 25),
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Backup Codec:'),
                              DropdownButton<String>(
                                value: _backupCodec,
                                icon: const Icon(
                                  Icons.arrow_drop_down,
                                  color: Colors.blue,
                                ),
                                elevation: 16,
                                style: const TextStyle(color: Colors.blue),
                                underline: Container(
                                  height: 2,
                                  color: Colors.blueAccent,
                                ),
                                onChanged: (String? value) {
                                  // This is called when the user selects an item.
                                  setState(() {
                                    _backupCodec = value!;
                                  });
                                },
                                items: [
                                  'Backup Codec',
                                  'VP8',
                                  'H264'
                                ].map<DropdownMenuItem<String>>((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                              )
                            ])),
                  ElevatedButton(
                    onPressed: _busy ? null : () => _connect(context),
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
                        const Text('CONNECT'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}
