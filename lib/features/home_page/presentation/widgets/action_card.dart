import 'package:flutter/material.dart';
import 'package:rmstock_scanner/utils/responsive_utils.dart';

import '../../../../constants/colors.dart';
import '../../../../constants/theme_colors.dart';
import '../../../../constants/txt_styles.dart';

class ActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final double? minHeight;

  const ActionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.minHeight,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final bool isTablet = context.isTablet;
    final double scale = isTablet
        ? (context.shortestSide / 768).clamp(0.85, 1.3)
        : 1.0;
    final double titleSize = isTablet ? (16 * scale).clamp(16.0, 19.0) : 16.0;
    final double subTitleSize =
        isTablet ? (14 * scale).clamp(12.0, 14.0) : 14.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Container(
        constraints: BoxConstraints(
          minHeight: minHeight ?? 0,
        ),
        decoration: BoxDecoration(
          gradient: colors.glassGradient,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: colors.glassBorder, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: colors.cardShadow,
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(15),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 17),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: getSmartTitle(
                            fontSize: titleSize,
                            color: kPrimaryColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: subTitleSize,
                            color: colors.onSurfaceMuted,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colors.surfaceAlt.withOpacity(0.6),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_forward_rounded,
                      color: kPrimaryColor,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}