import 'package:flutter/material.dart';
import 'package:rmmobile/utils/navigation_extension.dart';

import '../../../../constants/colors.dart';
import '../../../../constants/standard_dialog.dart';
import '../../../../constants/theme_colors.dart';

class StocktakeCommitErrorDialog extends StatelessWidget {
  const StocktakeCommitErrorDialog({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final bool isDark = colors.isDark;
    return StandardDialog(
      title: "Oops!",
      colors: colors,
      isDark: isDark,
      content: SingleChildScrollView(
        child: Center(
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
      ),
      actions: [
        DialogTextAction(
          label: "OK, Got it",
          style: DialogActionStyle.primary,
          onPressed: () => context.navigateBack(),
        ),
      ],
    );
  }
}
