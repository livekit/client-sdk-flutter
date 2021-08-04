import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:livekit_client/livekit_client.dart';
import 'room.dart';

void main() {
  // configure logs for debugging
  Logger.root.level = Level.FINE;
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
  });

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LiveKit Demo',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
      ),
      home: PreConnect(),
    );
  }
}

class PreConnect extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _PreConnectState(
      'ws://172.20.10.11:7880',
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE5ODQzNDMyMzUsImlzcyI6IkFQSU1teGlMOHJxdUt6dFpFb1pKVjlGYiIsImp0aSI6InNlY29uZCIsIm5iZiI6MTYyNDM0MzIzNSwidmlkZW8iOnsicm9vbSI6Im15cm9vbSIsInJvb21Kb2luIjp0cnVlfX0.USJmnqcLabtsX5A0ZIjguG7jnbVkbZxi5RyPxLOXgOg',
    );
  }
}

class _PreConnectState extends State<PreConnect> {
  String url;
  String token;

  _PreConnectState(this.url, this.token);

  _connect(BuildContext context) async {
    try {
      var room = await LiveKitClient.connect(this.url, this.token);
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) {
          return RoomWidget(room);
        }),
      );
    } catch (e) {
      print("could not connect $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Connect to LiveKit'),
      ),
      body: Center(
        child: Container(
          // width: 250,
          alignment: Alignment.center,
          margin: const EdgeInsets.all(10),
          child: Column(
            children: [
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'URL',
                ),
                onChanged: (value) => this.url,
                initialValue: this.url,
              ),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Token',
                ),
                onChanged: (value) => this.token,
                initialValue: this.token,
              ),
              TextButton(
                onPressed: () => _connect(context),
                child: Text('Connect'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
