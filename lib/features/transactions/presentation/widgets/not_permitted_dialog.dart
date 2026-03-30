import 'package:flutter/material.dart';

import '../../../../constants/colors.dart';
import '../../../../constants/theme_colors.dart';
import '../../../../utils/responsive_utils.dart';

/// Dialog for showing "Not Permitted" messages (e.g., stock availability errors)
class NotPermittedDialog extends StatelessWidget {
  final String message;
  final AppThemeColors colors;
  final bool isDark;

  const NotPermittedDialog({
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
      builder: (dialogContext) => NotPermittedDialog(
        message: message,
        colors: colors,
        isDark: isDark,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isTablet = context.isTablet;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isTablet ? 80 : 24,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: isTablet ? 450 : double.infinity,
        ),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E2733) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.4 : 0.15),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon and Title
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: kErrorColor.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.block_rounded,
                    color: kErrorColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Not Permitted!',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Message
            Text(
              message,
              style: TextStyle(
                fontSize: 16,
                height: 1.4,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
            const SizedBox(height: 20),

            // Button
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: kErrorColor,
                  side: const BorderSide(color: kErrorColor),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'OK',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
