//
//
//

import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  final _uriCtrl = TextEditingController();
  final _tokenCtrl = TextEditingController();
  bool _simulcast = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _readPrefs();
  }

  @override
  void dispose() {
    _uriCtrl.dispose();
    _tokenCtrl.dispose();
    super.dispose();
  }

  Future<void> _readPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _uriCtrl.text = prefs.getString(_storeKeyUri) ?? '';
    _tokenCtrl.text = prefs.getString(_storeKeyToken) ?? '';
    setState(() {
      _simulcast = prefs.getBool(_storeKeySimulcast) ?? false;
    });
  }

  Future<void> _writePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storeKeyUri, _uriCtrl.text);
    await prefs.setString(_storeKeyToken, _tokenCtrl.text);
    await prefs.setBool(_storeKeySimulcast, _simulcast);
  }

  Future<void> _connect(BuildContext ctx) async {
    //
    try {
      setState(() {
        _busy = true;
      });

      print('Connecting with url: ${_uriCtrl.text}, token: ${_tokenCtrl.text}...');

      final room = await LiveKitClient.connect(
        _uriCtrl.text,
        _tokenCtrl.text,
        options: ConnectOptions(
          defaultPublishOptions: TrackPublishOptions(
            simulcast: _simulcast,
          ),
        ),
      );

      // Save for next time
      await _writePrefs();

      await Navigator.push<void>(
        ctx,
        MaterialPageRoute(builder: (_) => RoomPage(room)),
      );
    } catch (error) {
      print('could not connect $error');
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
    // await _writePrefs();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Connect to LiveKit'),
        ),
        body: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(
              vertical: 20,
              horizontal: 20,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Theme.of(context).colorScheme.secondary),
            ),
            constraints: const BoxConstraints(
              maxWidth: 320,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _uriCtrl,
                  decoration: const InputDecoration(labelText: 'URL'),
                ),
                TextField(
                  controller: _tokenCtrl,
                  decoration: const InputDecoration(labelText: 'Token'),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: CheckboxListTile(
                    controlAffinity: ListTileControlAffinity.leading,
                    onChanged: (value) => _setSimulcast(value),
                    title: const Text('Use Simulcast'),
                    value: _simulcast,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: ElevatedButton(
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
                        const Text('Connect'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
