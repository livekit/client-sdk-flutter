//
// LiveKit
//

class RTCOfferOptions {
  //
  bool iceRestart = false;

  Map<String, dynamic> toMap() => <String, dynamic>{
        if (iceRestart) 'iceRestart': true,
      };
}
