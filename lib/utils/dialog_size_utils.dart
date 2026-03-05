import 'dart:math' as math;

import 'package:flutter/material.dart';

EdgeInsets dialogInsetPadding(BuildContext context) {
  final media = MediaQuery.of(context);
  final double width = media.size.width;
  final bool isTablet = media.size.shortestSide >= 600;
  final bool isPortrait = media.orientation == Orientation.portrait;

  if (isTablet) {
    final double horizontal = isPortrait
        ? math.min(width * 0.16, 220.0)
        : math.min(width * 0.22, 300.0);
    return EdgeInsets.symmetric(horizontal: horizontal, vertical: 24);
  }

  return const EdgeInsets.symmetric(horizontal: 16, vertical: 24);
}
