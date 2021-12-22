import 'dart:ui';

import 'package:meta/meta.dart';

@internal
@immutable
class RendererVisibility {
  final String rendererId;
  final String trackId;
  final bool visible;
  final Size size;
  const RendererVisibility({
    required this.rendererId,
    required this.trackId,
    required this.visible,
    required this.size,
  });
}

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
