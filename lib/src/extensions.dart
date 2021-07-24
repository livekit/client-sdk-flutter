class RTCConfiguration {
  int? iceCandidatePoolSize;
  List<RTCIceServer>? iceServers;
  String? iceTransportPolicy;

  Map<String, dynamic> toMap() {
    var iceServersMap = [];
    iceServers?.forEach((element) {
      iceServersMap.add(element.toMap());
    });
    return {
      // only supports unified plan
      'sdpSemantics': 'unified-plan',
      if (iceCandidatePoolSize != null)
        "iceCandidatePoolSize": iceCandidatePoolSize,
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
    return {
      "urls": urls,
      if (username != null) "username": username,
      if (credential != null) "credential": credential,
    };
  }
}

const RTCIceTransportPolicyAll = 'all';
const RTCIceTransportPolicyRelay = 'relay';
