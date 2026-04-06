import 'package:flutter/material.dart';

import '../constants/colors.dart';
import '../constants/theme_colors.dart';

/// A reusable iOS-specific "Done" button bar for numeric keyboards.
///
/// iOS numeric keypads don't have a built-in "Done" button like Android,
/// so this widget provides that functionality. It shows a bar above the keyboard
/// with a "Done" button when the associated [focusNode] has focus.
///
/// This widget only renders on iOS devices. On other platforms, it returns
/// an empty SizedBox.
///
/// Usage:
/// ```dart
/// Column(
///   children: [
///     // Your content...
///     IosDoneBar(
///       focusNode: myFocusNode,
///       onDone: () {
///         myFocusNode.unfocus();
///         // Do something with the input...
///       },
///     ),
///   ],
/// )
/// ```
class IosDoneBar extends StatelessWidget {
  /// The focus node to monitor. The bar will only show when this has focus.
  final FocusNode focusNode;

  /// Callback when the Done button is pressed.
  /// Typically used to unfocus the field and/or submit the value.
  final VoidCallback onDone;

  /// Optional custom label for the button. Defaults to "Done".
  final String label;

  const IosDoneBar({
    super.key,
    required this.focusNode,
    required this.onDone,
    this.label = "Done",
  });

  @override
  Widget build(BuildContext context) {
    // Only show on iOS
    if (Theme.of(context).platform != TargetPlatform.iOS) {
      return const SizedBox.shrink();
    }

    final colors = context.appColors;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isTablet = MediaQuery.of(context).size.shortestSide >= 600;
    final double textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
    final double uiScale = isTablet
        ? (1.0 + ((textScale - 1.0) * 0.35)).clamp(1.0, 1.2)
        : 1.0;

    return AnimatedBuilder(
      animation: focusNode,
      builder: (context, _) {
        if (!focusNode.hasFocus) return const SizedBox.shrink();

        return Container(
          height: (isTablet ? 48 : 44) * uiScale,
          decoration: BoxDecoration(
            color: isDark ? colors.surfaceAlt : Colors.grey.shade200,
            border: Border(
              top: BorderSide(
                color: isDark ? colors.divider : Colors.black12,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: onDone,
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: isTablet ? 18 : 16,
                    color: isDark ? colors.onSurface : kThirdColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
        );
      },
    );
  }
}

/// A version of [IosDoneBar] that can monitor multiple focus nodes.
///
/// Shows when any of the [focusNodes] has focus.
class IosDoneBarMulti extends StatelessWidget {
  /// The focus nodes to monitor. The bar will show when any of these has focus.
  final List<FocusNode> focusNodes;

  /// Callback when the Done button is pressed.
  final VoidCallback onDone;

  /// Optional custom label for the button. Defaults to "Done".
  final String label;

  const IosDoneBarMulti({
    super.key,
    required this.focusNodes,
    required this.onDone,
    this.label = "Done",
  });

  @override
  Widget build(BuildContext context) {
    // Only show on iOS
    if (Theme.of(context).platform != TargetPlatform.iOS) {
      return const SizedBox.shrink();
    }

    final colors = context.appColors;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isTablet = MediaQuery.of(context).size.shortestSide >= 600;
    final double textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
    final double uiScale = isTablet
        ? (1.0 + ((textScale - 1.0) * 0.35)).clamp(1.0, 1.2)
        : 1.0;

    return ListenableBuilder(
      listenable: Listenable.merge(focusNodes),
      builder: (context, _) {
        final hasFocus = focusNodes.any((fn) => fn.hasFocus);
        if (!hasFocus) return const SizedBox.shrink();

        return Container(
          height: (isTablet ? 48 : 44) * uiScale,
          decoration: BoxDecoration(
            color: isDark ? colors.surfaceAlt : Colors.grey.shade200,
            border: Border(
              top: BorderSide(
                color: isDark ? colors.divider : Colors.black12,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: onDone,
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: isTablet ? 18 : 16,
                    color: isDark ? colors.onSurface : kThirdColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
        );
      },
    );
  }
}
