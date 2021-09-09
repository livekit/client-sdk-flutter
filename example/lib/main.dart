import 'package:flutter/material.dart';
import 'package:livekit_example/theme.dart';
import 'package:logging/logging.dart';

import 'pages/connect.dart';

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
