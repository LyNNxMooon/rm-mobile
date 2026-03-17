import 'package:flutter/material.dart';

import 'colors.dart';

class AppThemeColors {
  const AppThemeColors(this.context);

  final BuildContext context;

  bool get isDark => Theme.of(context).brightness == Brightness.dark;

  Color get bg => isDark ? Theme.of(context).scaffoldBackgroundColor : kBgColor;

  Color get surface => isDark ? Theme.of(context).colorScheme.surface : kSecondaryColor;

  Color get surfaceAlt => isDark ? const Color(0xFF1B2430) : kSecondaryColor;

  Color get onSurface => isDark ? Theme.of(context).colorScheme.onSurface : kThirdColor;

    Color get onSurfaceMuted =>
      isDark ? Theme.of(context).colorScheme.onSurface.withOpacity(0.72) : kGreyColor;

    Color get onSurfaceFaint =>
      isDark ? Theme.of(context).colorScheme.onSurface.withOpacity(0.55) : kGreyColor.withOpacity(0.7);

    Color get glassFill =>
      isDark ? Colors.white.withOpacity(0.06) : kSecondaryColor.withOpacity(0.1);

    Color get glassBorder =>
      isDark ? Colors.white.withOpacity(0.16) : kSecondaryColor.withOpacity(0.6);

    Color get cardShadow =>
      isDark ? Colors.black.withOpacity(0.35) : kThirdColor.withOpacity(0.05);

  Color get divider => isDark ? const Color(0xFF22303B) : kGreyColor.withOpacity(0.2);

  Color get onHero => isDark ? Theme.of(context).colorScheme.onPrimary : kSecondaryColor;

  LinearGradient get heroGradient => isDark
      ? const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0C2B3B), Color(0xFF0E1116)],
        )
      : kGColor;

  LinearGradient get glassGradient => isDark
      ? LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1A232F).withOpacity(0.85),
            const Color(0xFF0F141B).withOpacity(0.65),
          ],
        )
      : kWColor;
}

extension AppThemeColorsX on BuildContext {
  AppThemeColors get appColors => AppThemeColors(this);
}
