import 'package:flutter/material.dart';
import '../../../../constants/colors.dart';
import '../../../../constants/standard_dialog.dart';
import '../../../../constants/theme_colors.dart';

class StocktakeQuestionDialog extends StatelessWidget {
  const StocktakeQuestionDialog({
    super.key,
    required this.message,
    required this.onYesPressed,
    this.title = "Are you sure?",
    this.onNoPressed,
  });

  final String title;
  final String message;
  final VoidCallback onYesPressed;
  final VoidCallback? onNoPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return StandardDialog(
      title: title,
      colors: colors,
      isDark: isDark,
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: kPrimaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.help_outline_rounded,
                  color: kPrimaryColor,
                  size: 32,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white70 : colors.onSurfaceMuted,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
      actions: [
        DialogTextAction(
          label: "No",
          style: DialogActionStyle.outline,
          onPressed: () {
            if (onNoPressed != null) {
              onNoPressed!();
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
        DialogTextAction(
          label: "Yes",
          style: DialogActionStyle.primary,
          onPressed: onYesPressed,
        ),
      ],
    );
  }
}
