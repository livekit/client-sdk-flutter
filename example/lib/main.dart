import 'package:flutter/material.dart';
import 'package:livekit_example/theme.dart';
import 'package:logging/logging.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'room.dart';

void main() {
  // configure logs for debugging
  Logger.root.level = Level.FINE;
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
  });

  WidgetsFlutterBinding.ensureInitialized();

  runApp(const LiveKitExampleApp());
}

class LiveKitExampleApp extends StatelessWidget {
  //
  const LiveKitExampleApp({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'LiveKit Flutter Example',
        theme: LiveKitTheme().buildThemeData(context),
        home: const ConnectPage(),
      );
}

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

  final _uriCtrl = TextEditingController();
  final _tokenCtrl = TextEditingController();

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
  }

  Future<void> _writePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storeKeyUri, _uriCtrl.text);
    await prefs.setString(_storeKeyToken, _tokenCtrl.text);
  }

  void _connect(BuildContext context) async {
    //
    try {
      print('Connecting with url: ${_uriCtrl.text}, token: ${_tokenCtrl.text}...');

      final room = await LiveKitClient.connect(
        _uriCtrl.text,
        _tokenCtrl.text,
      );

      // Save for next time
      await _writePrefs();

      Navigator.push<void>(
        context,
        MaterialPageRoute(builder: (context) {
          return RoomPage(room);
        }),
      );
    } catch (e) {
      print('could not connect $e');
    }
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
              border: Border.all(color: Theme.of(context).accentColor),
            ),
            constraints: const BoxConstraints(
              maxWidth: 320,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _uriCtrl,
                  decoration: const InputDecoration(
                    labelText: 'URL',
                  ),
                ),
                TextField(
                  controller: _tokenCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Token',
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 30),
                  child: ElevatedButton(
                    onPressed: () => _connect(context),
                    child: const Text('Connect'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
