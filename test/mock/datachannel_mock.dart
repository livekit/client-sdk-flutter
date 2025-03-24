// Copyright 2024 LiveKit, Inc.
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

import 'package:flutter_webrtc/flutter_webrtc.dart';

class MockDataChannel extends RTCDataChannel {
  final String? _label;
  final int _id;
  RTCDataChannelState? _state = RTCDataChannelState.RTCDataChannelOpen;
  Function(RTCDataChannelMessage data)? onMessageSend;
  late StreamController<RTCDataChannelState> stateChangeStreamController;
  MockDataChannel(this._id, this._label) {
    stateChangeStreamController =
        StreamController<RTCDataChannelState>.broadcast();
  }

  @override
  String? get label => _label;

  @override
  Future<void> send(RTCDataChannelMessage message) async {
    onMessageSend?.call(message);
  }

  @override
  RTCDataChannelState? get state => _state;

  @override
  Future<void> close() async {
    _state = RTCDataChannelState.RTCDataChannelClosing;
    _state = RTCDataChannelState.RTCDataChannelClosed;
  }

  @override
  // ignore: overridden_fields
  int? bufferedAmountLowThreshold = 0;

  @override
  int? get bufferedAmount => bufferedAmountLowThreshold;

  @override
  Future<int> getBufferedAmount() => Future.value(bufferedAmountLowThreshold);

  @override
  int? get id => _id;
}
