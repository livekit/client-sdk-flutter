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

import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;

import '../proto/livekit_models.pb.dart' as lk_models;

class BufferedDataPacket {
  final lk_models.DataPacket packet;
  final rtc.RTCDataChannelMessage message;
  final int sequence;

  BufferedDataPacket({
    required this.packet,
    required this.message,
    required this.sequence,
  });
}

class DataPacketBuffer {
  final List<BufferedDataPacket> _buffer = [];

  void push(BufferedDataPacket item) {
    _buffer.add(item);
  }

  void popToSequence(int sequence) {
    _buffer.removeWhere((item) => item.sequence <= sequence);
  }

  void alignBufferedAmount(int bufferedAmount) {
    if (bufferedAmount == 0) {
      _buffer.clear();
    }
  }

  List<BufferedDataPacket> getAll() {
    return List.from(_buffer);
  }

  void clear() {
    _buffer.clear();
  }

  int get length => _buffer.length;
  bool get isEmpty => _buffer.isEmpty;
  bool get isNotEmpty => _buffer.isNotEmpty;
}
