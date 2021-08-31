class RTCConfiguration {
  int? iceCandidatePoolSize;
  List<RTCIceServer>? iceServers;
  String? iceTransportPolicy;

  Map<String, dynamic> toMap() {
    final iceServersMap = <Map<String, dynamic>>[];
    for (final element in (iceServers ?? <RTCIceServer>[])) {
      iceServersMap.add(element.toMap());
    }
    return <String, dynamic>{
      // only supports unified plan
      'sdpSemantics': 'unified-plan',
      if (iceCandidatePoolSize != null) "iceCandidatePoolSize": iceCandidatePoolSize,
      "iceServers": iceServersMap,
      if (iceTransportPolicy != null) "iceTransportPolicy": iceTransportPolicy,
    };
  }
}

class RTCIceServer {
  List<String> urls;
  String? username;
  String? credential;

  RTCIceServer({required this.urls, this.username, this.credential});

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      "urls": urls,
      if (username != null) "username": username,
      if (credential != null) "credential": credential,
    };
  }
}

enum RTCIceTransportPolicy {
  all,
  relay,
}

extension RTCIceTransportPolicyExt on RTCIceTransportPolicy {
  String toStringValue() => {
        RTCIceTransportPolicy.all: 'all',
        RTCIceTransportPolicy.relay: 'relay',
      }[this]!;
}
