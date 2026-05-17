import 'dart:io';
import 'package:flutter/material.dart';

/// Breakpoint constants for responsive design.
/// Based on shortestSide of the screen.
class Breakpoints {
  Breakpoints._();

  /// Phone: shortestSide < 600
  static const double phone = 600;

  /// Medium Tablet: shortestSide >= 600
  static const double tablet = 600;

  /// Large Tablet (iPad Pro, etc.): shortestSide >= 900
  static const double largeTablet = 900;

  /// Large tablet detection via longestSide
  static const double longSideXLarge = 1366;

  /// Desktop navigation breakpoint: width >= 1280
  /// When window is this wide, use NavigationRail instead of BottomNav
  static const double desktopNav = 1280;

  /// Maximum content width for comfortable reading on large screens
  static const double maxContentWidth = 1200;
}

/// Device type classification.
enum DeviceType {
  phone,
  tablet,
  largeTablet,
  desktop,
}

/// Responsive information about the current device/screen.
class ResponsiveInfo {
  final Size size;
  final Orientation orientation;
  final DeviceType deviceType;
  final double textScale;
  final double uiScale;

  const ResponsiveInfo({
    required this.size,
    required this.orientation,
    required this.deviceType,
    required this.textScale,
    required this.uiScale,
  });

  double get shortestSide => size.shortestSide;
  double get longestSide => size.longestSide;
  double get width => size.width;
  double get height => size.height;

  bool get isPhone => deviceType == DeviceType.phone;
  bool get isTablet =>
      deviceType == DeviceType.tablet || deviceType == DeviceType.largeTablet;
  bool get isMediumTablet => deviceType == DeviceType.tablet;
  bool get isLargeTablet => deviceType == DeviceType.largeTablet;
  bool get isDesktop => deviceType == DeviceType.desktop;
  bool get isPortrait => orientation == Orientation.portrait;
  bool get isLandscape => orientation == Orientation.landscape;

  /// Whether the device is a mobile platform (iOS/Android).
  bool get isMobilePlatform => Platform.isIOS || Platform.isAndroid;

  /// Whether the device is a desktop platform (Windows/Linux/macOS).
  bool get isDesktopPlatform =>
      Platform.isWindows || Platform.isLinux || Platform.isMacOS;
}

/// Extension on BuildContext for easy responsive access.
extension ResponsiveContext on BuildContext {
  /// Get full responsive information for this context.
  ResponsiveInfo get responsive {
    final media = MediaQuery.of(this);
    final size = media.size;
    final shortestSide = size.shortestSide;
    final longestSide = size.longestSide;

    // Determine device type
    DeviceType deviceType;
    if (Platform.isWindows || Platform.isLinux) {
      deviceType = DeviceType.desktop;
    } else if (shortestSide >= Breakpoints.largeTablet) {
      deviceType = DeviceType.largeTablet;
    } else if (shortestSide >= Breakpoints.tablet) {
      deviceType = DeviceType.tablet;
    } else {
      deviceType = DeviceType.phone;
    }

    // Calculate text scale (3-tier: phone, medium tablet, large tablet)
    double textScale = 1.0;
    if (shortestSide >= Breakpoints.tablet) {
      if (shortestSide >= Breakpoints.largeTablet || longestSide >= Breakpoints.longSideXLarge) {
        // Large Tablet (≥900)
        textScale = 1.2;
      } else {
        // Medium Tablet (600-900) - reduced scaling
        textScale = 1;
      }
    }

    // Calculate UI scale from text scale
    double uiScale = 1.0;
    if (textScale > 1.0) {
      uiScale = (1.0 + ((textScale - 1.0) * 0.65)).clamp(1.0, 1.42);
    }

    return ResponsiveInfo(
      size: size,
      orientation: media.orientation,
      deviceType: deviceType,
      textScale: textScale,
      uiScale: uiScale,
    );
  }

  // Quick accessors for common checks
  bool get isPhone => responsive.isPhone;
  bool get isTablet => responsive.isTablet;
  bool get isMediumTablet => responsive.isMediumTablet;
  bool get isLargeTablet => responsive.isLargeTablet;
  bool get isDesktop => responsive.isDesktop;
  bool get isPortrait => responsive.isPortrait;
  bool get isLandscape => responsive.isLandscape;
  bool get isMobilePlatform => responsive.isMobilePlatform;
  bool get isDesktopPlatform => responsive.isDesktopPlatform;

  /// Whether to use desktop navigation (NavigationRail)
  /// Only activates on desktop OS platforms (Windows, macOS, Linux)
  bool get useDesktopNav => isDesktopPlatform;

  /// Screen width
  double get screenWidth => MediaQuery.of(this).size.width;

  /// Screen height
  double get screenHeight => MediaQuery.of(this).size.height;

  /// Shortest side of the screen
  double get shortestSide => MediaQuery.of(this).size.shortestSide;

  /// Longest side of the screen
  double get longestSide => MediaQuery.of(this).size.longestSide;
}

/// Helper class for responsive value selection.
class ResponsiveValue {
  ResponsiveValue._();

  /// Select a value based on device type.
  /// Returns [phone] for phones, [tablet] for tablets, [largeTablet] for large tablets.
  /// If [largeTablet] is not provided, falls back to [tablet].
  static T of<T>(
    BuildContext context, {
    required T phone,
    required T tablet,
    T? largeTablet,
    T? desktop,
  }) {
    final info = context.responsive;

    if (info.isDesktop && desktop != null) {
      return desktop;
    }
    if (info.isLargeTablet) {
      return largeTablet ?? tablet;
    }
    if (info.isTablet) {
      return tablet;
    }
    return phone;
  }

  /// Select a value based on orientation.
  static T byOrientation<T>(
    BuildContext context, {
    required T portrait,
    required T landscape,
  }) {
    return context.isPortrait ? portrait : landscape;
  }
}

/// Extension for responsive sizing with clamp.
extension ResponsiveSizing on num {
  /// Scale this value by the UI scale factor with optional clamp.
  double scaledBy(double scale, {double? min, double? max}) {
    double result = toDouble() * scale;
    if (min != null && max != null) {
      return result.clamp(min, max);
    }
    if (min != null) return result < min ? min : result;
    if (max != null) return result > max ? max : result;
    return result;
  }

  /// Get responsive value: returns [phone] for phones, [tablet] for tablets.
  double responsiveValue(
    BuildContext context, {
    required double phone,
    required double tablet,
    double? largeTablet,
  }) {
    final info = context.responsive;
    if (info.isLargeTablet && largeTablet != null) {
      return largeTablet;
    }
    if (info.isTablet) {
      return tablet;
    }
    return phone;
  }
}
