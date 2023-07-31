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

import 'package:flutter_webrtc/flutter_webrtc.dart';

class MockDataChannel extends RTCDataChannel {
  final String? _label;
  final int _id;
  RTCDataChannelState? _state = RTCDataChannelState.RTCDataChannelOpen;

  MockDataChannel(this._id, this._label);

  @override
  String? get label => _label;

  @override
  Future<void> send(RTCDataChannelMessage message) async {}

  @override
  RTCDataChannelState? get state => _state;

  @override
  Future<void> close() async {
    _state = RTCDataChannelState.RTCDataChannelClosing;
    _state = RTCDataChannelState.RTCDataChannelClosed;
  }

  @override
  // TODO: implement bufferedAmount
  int? get bufferedAmount => throw UnimplementedError();

  @override
  int? get id => _id;
}
