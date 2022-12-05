import 'dart:async';

import 'package:flutter_window_close/flutter_window_close.dart';

class AppStateListener {
  AppStateListener._internal() {
    FlutterWindowClose.setWindowShouldCloseHandler(() async {
      onWindowShouldClose.add('close');
      return true;
    });
  }
  static final AppStateListener instance = AppStateListener._internal();
  final StreamController<String> onWindowShouldClose =
      StreamController.broadcast(sync: true);
}
