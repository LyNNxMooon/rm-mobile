import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:rmstock_scanner/utils/responsive_utils.dart';

EdgeInsets dialogInsetPadding(BuildContext context) {
  final double width = context.screenWidth;
  final bool isTablet = context.isTablet;
  final bool isPortrait = context.isPortrait;

  if (isTablet) {
    final double horizontal = isPortrait
        ? math.min(width * 0.16, 220.0)
        : math.min(width * 0.22, 300.0);
    return EdgeInsets.symmetric(horizontal: horizontal, vertical: 24);
  }

  return const EdgeInsets.symmetric(horizontal: 16, vertical: 24);
}
