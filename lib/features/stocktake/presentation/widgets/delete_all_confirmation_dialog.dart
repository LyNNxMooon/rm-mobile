import 'package:flutter/material.dart';
import 'package:rmstock_scanner/utils/navigation_extension.dart';

import '../../../../constants/colors.dart';
import '../../../../constants/theme_colors.dart';
import '../../../../utils/dialog_size_utils.dart';

class StocktakeDeleteConfirmationDialog extends StatelessWidget {
  const StocktakeDeleteConfirmationDialog({
    super.key,
    required this.onConfirm,
    this.title = "Are you really sure?",
    this.message = "This will permanently remove all counted stock items and they have not been committed to RM!",
  });

  final VoidCallback onConfirm;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final bool isDark = colors.isDark;
    return Dialog(
      insetPadding: dialogInsetPadding(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 10,
      backgroundColor: isDark ? const Color(0xFF2B3644) : colors.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: kErrorColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.warning,
                  color: kErrorColor,
                  size: 72,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: kErrorColor,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.white70 : colors.onSurface,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () => context.navigateBack(),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                        padding: EdgeInsets.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                        side: BorderSide(
                          color: isDark ? Colors.white24 : colors.divider,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        "Cancel",
                        textScaler: TextScaler.noScaling,
                        style: TextStyle(
                          color: isDark ? Colors.white : colors.onSurface,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        context.navigateBack();
                        onConfirm();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kErrorColor,
                        foregroundColor: colors.onHero,
                        minimumSize: const Size(double.infinity, 48),
                        padding: EdgeInsets.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        "Delete All",
                        textScaler: TextScaler.noScaling,
                        style: TextStyle(
                          color: colors.onHero,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
