import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;

class HardwarePreviewer {
  HardwarePreviewer();
  rtc.RTCPeerConnection? _sender;
  rtc.RTCPeerConnection? _receiver;

  Map<String, dynamic> dummyMap = <String, dynamic>{};
  Timer? _timer;

  Future<void> start() async {
    if (_receiver != null || _sender != null) return;
    _sender = await rtc.createPeerConnection(dummyMap);
    _receiver = await rtc.createPeerConnection(dummyMap);

    _sender?.onIceCandidate = (candidate) => _receiver?.addCandidate(candidate);
    _receiver?.onIceCandidate = (candidate) => _sender?.addCandidate(candidate);

    // Connect the sender with the receiver
    var offer = await _sender!.createOffer(dummyMap);

    await _receiver!.setRemoteDescription(offer);
    var answer = await _receiver!.createAnswer();

    await _sender!.setLocalDescription(offer);
    await _receiver!.setLocalDescription(answer);

    await _sender!.setRemoteDescription(answer);

    _timer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      _sender?.getStats().then((reports) {
        for (var report in reports) {
          if (report.type != 'ssrc') {
            continue;
          }
          report.values.forEach((dynamic key, dynamic value) {
            if (key != 'audioInputLevel') return;
            if (kDebugMode) {
              print('$key : ${value.toString()} ');
            }
          });
        }
      });
    });
  }

  Future<void> stop() async {
    await _sender?.close();
    await _receiver?.close();
    _sender = null;
    _receiver = null;
    _timer?.cancel();
    _timer = null;
  }
}
