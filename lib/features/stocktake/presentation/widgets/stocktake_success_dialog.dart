import 'package:flutter/material.dart';
//import '../../../../constants/colors.dart';
import '../../../../constants/standard_dialog.dart';
import '../../../../constants/theme_colors.dart';

class StocktakeSuccessDialog extends StatelessWidget {
  const StocktakeSuccessDialog({
    super.key,
    required this.message,
    required this.onOkayPressed,
  });

  final String message;
  final VoidCallback onOkayPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final bool isDark = colors.isDark;
    
    // Split message into title (first paragraph) and body (rest)
    final parts = message.split('\n\n');
    final titleText = parts.isNotEmpty ? parts[0] : message;
    final bodyText = parts.length > 1 ? parts.sublist(1).join('\n\n') : null;
    
    return StandardDialog(
      title: "Success!",
      colors: colors,
      isDark: isDark,
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Success Icon Bubble
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.check_circle_rounded,
                  color: Colors.green,
                  size: 32,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              titleText,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : colors.onSurfaceMuted,
                height: 1.5,
              ),
            ),
            if (bodyText != null) ...[
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),
              Text(
                bodyText,
                textAlign: TextAlign.start,
                style: TextStyle(
                  fontSize: 16,
                  color: isDark ? Colors.white70 : colors.onSurfaceMuted,
                  height: 1.5,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        DialogTextAction(
          label: "OK",
          style: DialogActionStyle.primary,
          onPressed: onOkayPressed,
        ),
      ],
    );
  }
}
