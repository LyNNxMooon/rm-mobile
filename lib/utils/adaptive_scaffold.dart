import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/theme_colors.dart';
import 'responsive_utils.dart';

/// Navigation item configuration for the adaptive scaffold.
class AdaptiveNavItem {
  final IconData icon;
  final IconData? selectedIcon;
  final String label;

  const AdaptiveNavItem({
    required this.icon,
    this.selectedIcon,
    required this.label,
  });
}

/// A scaffold that adapts between mobile (BottomNavigationBar) and desktop
/// (NavigationRail) layouts based on screen width.
///
/// This widget provides a consistent navigation pattern across platforms while
/// keeping the body content DRY - you only define the content once.
class AdaptiveScaffold extends StatelessWidget {
  /// The main body content of the scaffold.
  final Widget body;

  /// List of navigation items to display.
  final List<AdaptiveNavItem> navigationItems;

  /// Currently selected navigation index.
  final int selectedIndex;

  /// Callback when a navigation item is tapped.
  final ValueChanged<int> onDestinationSelected;

  /// Background color for the body container.
  /// If null, uses the default scaffold background.
  final Color? backgroundColor;

  /// Decoration for the body container (e.g., gradient).
  final BoxDecoration? bodyDecoration;

  /// Whether to extend the body behind the bottom navigation bar.
  final bool extendBody;

  /// Additional leading widget for the NavigationRail (desktop only).
  /// Typically used for a logo or app icon.
  final Widget? railLeading;

  /// Additional trailing widget for the NavigationRail (desktop only).
  /// Typically used for settings or profile button.
  final Widget? railTrailing;

  /// Whether the NavigationRail should show extended labels.
  /// When true, shows icon + label side by side (like a drawer).
  final bool extendedRail;

  /// Width of the NavigationRail when extended.
  final double extendedRailWidth;

  /// Whether to show labels on the NavigationRail.
  final NavigationRailLabelType railLabelType;

  /// Breakpoint at which to switch from mobile to desktop navigation.
  /// Defaults to [Breakpoints.desktopNav] (840).
  final double? desktopBreakpoint;

  const AdaptiveScaffold({
    super.key,
    required this.body,
    required this.navigationItems,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.backgroundColor,
    this.bodyDecoration,
    this.extendBody = false,
    this.railLeading,
    this.railTrailing,
    this.extendedRail = false,
    this.extendedRailWidth = 200,
    this.railLabelType = NavigationRailLabelType.all,
    this.desktopBreakpoint,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool useDesktop = context.useDesktopNav;

        if (useDesktop) {
          return _buildDesktopLayout(context);
        } else {
          return _buildMobileLayout(context);
        }
      },
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    final colors = context.appColors;

    return Scaffold(
      extendBody: extendBody,
      backgroundColor: backgroundColor ?? kPrimaryColor,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        type: BottomNavigationBarType.fixed,
        backgroundColor: colors.isDark ? colors.surface : Colors.white,
        selectedItemColor: kPrimaryColor,
        unselectedItemColor: colors.onSurfaceMuted,
        onTap: onDestinationSelected,
        items: navigationItems
            .map(
              (item) => BottomNavigationBarItem(
                icon: Icon(item.icon),
                activeIcon: item.selectedIcon != null
                    ? Icon(item.selectedIcon)
                    : null,
                label: item.label,
              ),
            )
            .toList(),
      ),
      body: bodyDecoration != null
          ? Container(
              width: double.infinity,
              height: double.infinity,
              decoration: bodyDecoration,
              child: body,
            )
          : body,
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    final colors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: backgroundColor ?? kPrimaryColor,
      body: bodyDecoration != null
          ? Container(
              width: double.infinity,
              height: double.infinity,
              decoration: bodyDecoration,
              child: Row(
                children: [
                  _buildNavigationRail(context, colors, isDark),
                  Expanded(child: body),
                ],
              ),
            )
          : Row(
              children: [
                _buildNavigationRail(context, colors, isDark),
                Expanded(child: body),
              ],
            ),
    );
  }

  Widget _buildNavigationRail(
    BuildContext context,
    AppThemeColors colors,
    bool isDark,
  ) {
    return NavigationRail(
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      extended: extendedRail,
      minExtendedWidth: extendedRailWidth,
      labelType: extendedRail ? NavigationRailLabelType.none : railLabelType,
      backgroundColor: isDark ? colors.surface : Colors.white,
      selectedIconTheme: IconThemeData(color: kPrimaryColor),
      unselectedIconTheme: IconThemeData(color: colors.onSurfaceMuted),
      selectedLabelTextStyle: TextStyle(
        color: kPrimaryColor,
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
      unselectedLabelTextStyle: TextStyle(
        color: colors.onSurfaceMuted,
        fontSize: 12,
      ),
      indicatorColor: kPrimaryColor.withOpacity(0.12),
      leading: railLeading,
      trailing: railTrailing,
      destinations: navigationItems
          .map(
            (item) => NavigationRailDestination(
              icon: Icon(item.icon),
              selectedIcon: item.selectedIcon != null
                  ? Icon(item.selectedIcon)
                  : Icon(item.icon),
              label: Text(item.label),
            ),
          )
          .toList(),
    );
  }
}

/// A widget that constrains its child to a maximum width and centers it.
/// Useful for preventing content from stretching too wide on large screens.
class ConstrainedContent extends StatelessWidget {
  /// The child widget to constrain.
  final Widget child;

  /// Maximum width of the content.
  /// Defaults to [Breakpoints.maxContentWidth] (1200).
  final double maxWidth;

  /// Alignment of the constrained content within available space.
  final Alignment alignment;

  /// Padding around the constrained content.
  final EdgeInsetsGeometry? padding;

  const ConstrainedContent({
    super.key,
    required this.child,
    this.maxWidth = Breakpoints.maxContentWidth,
    this.alignment = Alignment.topCenter,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: child,
    );

    if (padding != null) {
      content = Padding(padding: padding!, child: content);
    }

    return Align(
      alignment: alignment,
      child: content,
    );
  }
}
