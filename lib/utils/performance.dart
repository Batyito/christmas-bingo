import 'package:flutter/widgets.dart';

/// Returns a performance scale in range [0.5, 1.0] where lower means fewer particles.
/// Heuristic based on screen area and devicePixelRatio to keep effects smooth on low-end devices.
double performanceScaleFromContext(BuildContext context) {
  final mq = MediaQuery.maybeOf(context);
  if (mq == null) return 0.9;
  final size = mq.size;
  final dpr = mq.devicePixelRatio;
  final area = size.width * size.height * dpr * dpr; // approximate pixel count

  // Heuristic buckets
  if (area > 3200000) {
    return 0.6; // very dense/high-res screens -> reduce density
  } else if (area > 2200000) {
    return 0.75;
  } else {
    return 1.0;
  }
}
