import 'package:flutter/material.dart';

import '../../../../constants/colors.dart';
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
    final bool isTablet = MediaQuery.of(context).size.shortestSide >= 600;
    final double scale = isTablet
        ? (MediaQuery.of(context).size.shortestSide / 768).clamp(0.85, 1.3)
        : 1.0;
    final double titleSize = isTablet ? (16 * scale).clamp(16.0, 19.0) : 16.0;
    final double subTitleSize = isTablet ? (14 * scale).clamp(12.0, 14.0) : 14.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Container(
        constraints: BoxConstraints(
          minHeight: minHeight ?? 0,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              kSecondaryColor.withOpacity(0.95),
              kSecondaryColor.withOpacity(0.70),
            ],
          ),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: kSecondaryColor.withOpacity(0.6),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: kThirdColor.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(15), // Match container radius
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
                          style: TextStyle(fontSize: subTitleSize, color: kGreyColor),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10), // Prevent text touching icon
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: kSecondaryColor.withOpacity(0.5),
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
