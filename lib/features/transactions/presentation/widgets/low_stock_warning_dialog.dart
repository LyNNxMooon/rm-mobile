import 'package:flutter/material.dart';

import '../../../../constants/theme_colors.dart';
import '../../../../utils/responsive_utils.dart';
import '../../../../constants/standard_dialog.dart';

/// Dialog for showing low stock warning message
class LowStockWarningDialog extends StatelessWidget {
  final String message;
  final AppThemeColors colors;
  final bool isDark;

  const LowStockWarningDialog({
    super.key,
    required this.message,
    required this.colors,
    required this.isDark,
  });

  /// Show the dialog
  static Future<void> show({
    required BuildContext context,
    required String message,
    required AppThemeColors colors,
    required bool isDark,
  }) {
    return showDialog(
      context: context,
      builder: (dialogContext) => LowStockWarningDialog(
        message: message,
        colors: colors,
        isDark: isDark,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isTablet = context.isTablet;
    final bool useDesktopNav = context.useDesktopNav;

    return StandardDialog(
      title: 'Low Stock Alert',
      colors: colors,
      isDark: isDark,
      maxWidth: useDesktopNav ? 500 : (isTablet ? 450 : double.infinity),
      content: Text(
        message,
        style: TextStyle(
          fontSize: 16,
          height: 1.4,
          color: isDark ? Colors.white70 : Colors.black54,
        ),
      ),
      actions: [
        DialogTextAction(
          label: 'Cancel',
          style: DialogActionStyle.cancelOutline,
          onPressed: () => Navigator.pop(context),
        ),
        DialogTextAction(
          label: 'OK',
          style: DialogActionStyle.primary,
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }
}
