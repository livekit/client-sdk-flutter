import 'dart:ui';

import 'package:meta/meta.dart';

@internal
@immutable
class VisibilityState {
  final bool visible;
  final Size size;
  const VisibilityState({
    required this.visible,
    required this.size,
  });

  VisibilityState copyWith({
    bool? visible,
    Size? size,
  }) =>
      VisibilityState(
        visible: visible ?? this.visible,
        size: size ?? this.size,
      );

  @override
  int get hashCode => hashValues(visible, size);

  @override
  bool operator ==(Object other) =>
      other is VisibilityState &&
      visible == other.visible &&
      size == other.size;
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
