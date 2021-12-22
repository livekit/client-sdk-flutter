
import 'dart:ui';

import 'package:meta/meta.dart';

@internal
class RendererVisibility {
  final String rendererId;
  final String trackId;
  final bool visible;
  final Size size;
  RendererVisibility({
    required this.rendererId,
    required this.trackId,
    required this.visible,
    required this.size,
  });
}