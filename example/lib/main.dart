import 'package:flutter/material.dart';
import 'package:livekit_example/theme.dart';
import 'package:logging/logging.dart';
import 'package:livekit_client/livekit_client.dart';
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
        home: const PreConnectWidget(
          url: '',
          token: '',
        ),
      );
}

class PreConnectWidget extends StatefulWidget {
  //
  final String url;
  final String token;

  const PreConnectWidget({
    required this.url,
    required this.token,
    Key? key,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _PreConnectWidgetState();
}

class _PreConnectWidgetState extends State<PreConnectWidget> {
  //
  final _urlCtrl = TextEditingController();
  final _tokenCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _urlCtrl.text = widget.url;
    _tokenCtrl.text = widget.token;
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    _tokenCtrl.dispose();
    super.dispose();
  }

  void _connect(BuildContext context) async {
    try {
      print('Connecting with url: ${_urlCtrl.text}, token: ${_tokenCtrl.text}...');

      final room = await LiveKitClient.connect(
        _urlCtrl.text,
        _tokenCtrl.text,
      );

      Navigator.push<void>(
        context,
        MaterialPageRoute(builder: (context) {
          return RoomWidget(room);
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
                  controller: _urlCtrl,
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
