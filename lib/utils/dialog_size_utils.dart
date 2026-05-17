import 'dart:io' show Platform;
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:rmmobile/utils/responsive_utils.dart';

/// Returns true if running on desktop (Windows, Linux, macOS)
bool get isDesktopPlatform =>
    Platform.isWindows || Platform.isLinux || Platform.isMacOS;

EdgeInsets dialogInsetPadding(BuildContext context) {
  final double width = context.screenWidth;
  final double height = context.screenHeight;
  final bool isTablet = context.isTablet;
  final bool isPortrait = context.isPortrait;

  // Desktop: center dialog with comfortable margins
  if (isDesktopPlatform) {
    // For desktop, use larger padding that scales with window size
    final double horizontal = math.max(width * 0.15, 50.0);
    final double vertical = math.max(height * 0.08, 40.0);
    return EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical);
  }

  if (isTablet) {
    final double horizontal = isPortrait
        ? math.min(width * 0.16, 220.0)
        : math.min(width * 0.22, 300.0);
    return EdgeInsets.symmetric(horizontal: horizontal, vertical: 24);
  }

  return const EdgeInsets.symmetric(horizontal: 16, vertical: 24);
}
