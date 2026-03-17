import 'package:flutter/material.dart';
import 'package:rmstock_scanner/features/stocktake/presentation/screens/stocktake_history_screen.dart';
import 'package:rmstock_scanner/utils/navigation_extension.dart';

import '../../../../constants/colors.dart';
import '../../../../constants/theme_colors.dart';

class StocktakeSearchAndFilterBar extends StatelessWidget {
  final ValueChanged<String>? onChanged;
  final VoidCallback? onFilterTap;

  const StocktakeSearchAndFilterBar({
    super.key,
    this.onChanged,
    this.onFilterTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final bool isTablet = MediaQuery.of(context).size.shortestSide >= 600;
    final double textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
    final double uiScale = isTablet
        ? (1.0 + ((textScale - 1.0) * 0.35)).clamp(1.0, 1.2)
        : 1.0;
    final double actionSize = (isTablet ? 48 : 42) * uiScale;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15.0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: colors.cardShadow,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                onChanged: onChanged,
                decoration: InputDecoration(
                  hintText:
                      "Search barcode or description...", // Shortened hint
                  hintStyle: TextStyle(
                    color: colors.onSurfaceMuted,
                    fontSize: 13,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: kPrimaryColor,
                    size: 20,
                  ),
                  filled: true,
                  fillColor: colors.surface,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  isDense: true, // Compact
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colors.divider, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: kPrimaryColor, width: 1.5),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),
          Material(
            color: colors.surface,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: () {
                context.navigateToNext(const StocktakeHistoryScreen());
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: actionSize,
                width: actionSize,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.divider, width: 1),
                ),
                child: Icon(
                  Icons.history,
                  color: colors.onSurface,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
