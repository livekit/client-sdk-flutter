import 'package:flutter_webrtc/flutter_webrtc.dart';

class MockDataChannel extends RTCDataChannel {
  final String? _label;
  RTCDataChannelState? _state = RTCDataChannelState.RTCDataChannelOpen;

  MockDataChannel(this._label);

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
}
