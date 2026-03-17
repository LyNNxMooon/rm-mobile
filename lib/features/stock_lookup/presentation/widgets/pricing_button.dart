import 'package:flutter/material.dart';
import '../../../../constants/colors.dart';
import '../../../../constants/theme_colors.dart';

class PricingButton extends StatelessWidget {
  const PricingButton({
    super.key,
    required this.onTap,
    required this.verticalPadding,
  });

  final VoidCallback onTap;
  final double verticalPadding;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final bool isDark = colors.isDark;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: verticalPadding),
        decoration: _buttonDecoration(colors, isDark),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.sell_outlined,
              color: kPrimaryColor,
              size: 20,
            ),
            const SizedBox(width: 8),
            const Text(
              "PRICING",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: kPrimaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  BoxDecoration _buttonDecoration(AppThemeColors colors, bool isDark) {
    return BoxDecoration(
      gradient: isDark
          ? colors.glassGradient
          : LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                kSecondaryColor.withOpacity(0.95),
                kSecondaryColor.withOpacity(0.7),
              ],
            ),
      borderRadius: BorderRadius.circular(7),
      border: Border.all(
        color: isDark
            ? colors.glassBorder
            : kSecondaryColor.withOpacity(0.6),
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: isDark ? colors.cardShadow : kThirdColor.withOpacity(0.05),
          blurRadius: 15,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }
}
