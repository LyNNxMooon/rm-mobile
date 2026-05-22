import 'package:flutter/material.dart';

import '../../../../constants/theme_colors.dart';
import '../../../../entities/vos/customer_vo.dart';
import '../../../../utils/responsive_utils.dart';
import '../../../../constants/standard_dialog.dart';

/// Dialog for showing customer comments/messages
class CustomerCommentsDialog extends StatelessWidget {
  final CustomerVO customer;
  final AppThemeColors colors;
  final bool isDark;

  const CustomerCommentsDialog({
    super.key,
    required this.customer,
    required this.colors,
    required this.isDark,
  });

  /// Show the dialog
  static Future<void> show({
    required BuildContext context,
    required CustomerVO customer,
    required AppThemeColors colors,
    required bool isDark,
  }) {
    return showDialog(
      context: context,
      builder: (dialogContext) => CustomerCommentsDialog(
        customer: customer,
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
      title: 'Customer Message',
      colors: colors,
      isDark: isDark,
      maxWidth: useDesktopNav ? 500 : (isTablet ? 450 : double.infinity),
      content: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          customer.comments,
          style: TextStyle(
            fontSize: 15,
            height: 1.4,
            color: isDark ? Colors.white : Colors.black87,
          ),
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
