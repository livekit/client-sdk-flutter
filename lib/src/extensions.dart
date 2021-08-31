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

class RTCConfiguration {
  int? iceCandidatePoolSize;
  List<RTCIceServer>? iceServers;
  RTCIceTransportPolicy? iceTransportPolicy;

  Map<String, dynamic> toMap() {
    //
    final iceServersMap = <Map<String, dynamic>>[
      if (iceServers != null)
        for (final element in iceServers!) element.toMap()
    ];

    return <String, dynamic>{
      // only supports unified plan
      'sdpSemantics': 'unified-plan',
      if (iceServersMap.isNotEmpty) 'iceServers': iceServersMap,
      if (iceCandidatePoolSize != null) 'iceCandidatePoolSize': iceCandidatePoolSize,
      if (iceTransportPolicy != null) 'iceTransportPolicy': iceTransportPolicy!.toStringValue(),
    };
  }
}

class RTCIceServer {
  List<String> urls;
  String? username;
  String? credential;

  RTCIceServer({
    required this.urls,
    this.username,
    this.credential,
  });

  Map<String, dynamic> toMap() => <String, dynamic>{
        'urls': urls,
        if (username != null) 'username': username,
        if (credential != null) 'credential': credential,
      };
}
