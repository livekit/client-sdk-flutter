// Copyright 2023 LiveKit, Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

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
