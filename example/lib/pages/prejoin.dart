import 'dart:async';

import 'package:dropdown_textfield/dropdown_textfield.dart';
import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:random_name_generator/random_name_generator.dart';

import '../widgets/text_field.dart';

class PreJoinPage extends StatefulWidget {
  const PreJoinPage({
    Key? key,
  }) : super(key: key);

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
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  _join(BuildContext context) {
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
    setState(() {});
    /*
    Navigator.of(context).pushNamed('/room', arguments: {
      'videoInput': videoInput,
      'audioInput': audioInput,
      'displayName': displayName,
    });
    */
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
                    const Padding(
                        padding: EdgeInsets.only(bottom: 10),
                        child: SizedBox(
                          width: 320,
                          height: 240,
                          child: Placeholder(),
                        )),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 10),
                      child: Text(
                        'Camera:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
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
                            setState(() {});
                          }
                        },
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 10),
                      child: Text(
                        'Microphone:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
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
                            setState(() {});
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
