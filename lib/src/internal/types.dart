import 'package:meta/meta.dart';

@internal
@immutable
class RTCOfferOptions {
  final bool iceRestart;

  const RTCOfferOptions({
    this.iceRestart = false,
  });

  Map<String, dynamic> toMap() => <String, dynamic>{
        if (iceRestart) 'iceRestart': true,
      };
}
