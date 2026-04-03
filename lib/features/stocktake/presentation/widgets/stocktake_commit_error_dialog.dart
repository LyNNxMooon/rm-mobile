import 'package:flutter/material.dart';
import 'package:rmstock_scanner/utils/navigation_extension.dart';
import 'package:rmstock_scanner/utils/dialog_size_utils.dart';

import '../../../../constants/colors.dart';
import '../../../../constants/theme_colors.dart';

class StocktakeCommitErrorDialog extends StatelessWidget {
  const StocktakeCommitErrorDialog({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final bool isDark = colors.isDark;
    return Dialog(
      insetPadding: dialogInsetPadding(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: isDark
            ? const BorderSide(color: Colors.white30, width: 1)
            : BorderSide.none,
      ),
      elevation: 10,
      backgroundColor: isDark ? colors.surfaceAlt : colors.surface,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: kErrorColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  Icons.warning_amber_rounded,
                  color: kErrorColor,
                  size: 32,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Oops!",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : colors.onSurface,
              ),
            ),
            const SizedBox(height: 12),

            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white70 : colors.onSurfaceMuted,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  context.navigateBack();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  foregroundColor: colors.onHero,
                  minimumSize: const Size(double.infinity, 48),
                  padding: EdgeInsets.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  "Okay, Got it",
                  textScaler: TextScaler.noScaling,
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.onHero,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
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
