import 'package:flutter/material.dart';
import 'package:rmstock_scanner/constants/colors.dart';

class EmptyStockState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const EmptyStockState({
    super.key,
    this.message = "No items found",
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final bool isTablet = media.size.shortestSide >= 600;
    final double outerSize = isTablet ? 190 : 160;
    final double innerSize = isTablet ? 155 : 130;
    final double iconSize = isTablet ? 92 : 80;
    final double bottomGap = isTablet ? 30 : 50;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              // Outer Decorative Ring
              Container(
                width: outerSize,
                height: outerSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: kPrimaryColor.withOpacity(0.2),
                    width: 2,
                  ),
                ),
              ),

              // Inner Filled Circle
              Container(
                width: innerSize,
                height: innerSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: kPrimaryColor.withOpacity(0.1),
                ),
                child: Center(
                  // Using an "Open Box" icon usually signifies "Empty" better than a rocket
                  child: SizedBox(
                    width: iconSize,
                    height: iconSize,
                    child: Image.asset(
                      "assets/images/box.png",
                      fit: BoxFit.fill,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          Text(
            message,
            style: const TextStyle(
              color: kGreyColor,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),

          if (onRetry != null) ...[
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text("Refresh List"),
              style: TextButton.styleFrom(foregroundColor: kPrimaryColor),
            ),
          ],

          SizedBox(height: bottomGap),
        ],
      ),
    );
  }
}
