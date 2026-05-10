import 'package:flutter/material.dart';
import 'package:rmmobile/features/stocktake/presentation/screens/stocktake_history_screen.dart';
import 'package:rmmobile/utils/navigation_extension.dart';

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
    final bool isDark = colors.isDark;
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
            child: SizedBox(
              height: actionSize,
              child: TextField(
                onChanged: onChanged,
                textAlignVertical: TextAlignVertical.center,
                expands: true,
                maxLines: null,
                decoration: InputDecoration(
                  hintText:
                      "Search barcode or description...", // Shortened hint
                  hintStyle: TextStyle(
                    color: isDark ? Colors.white70 : colors.onSurfaceMuted,
                    fontSize: 13,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: isDark ? Colors.white70 : kPrimaryColor,
                    size: 20,
                  ),
                  filled: true,
                  fillColor: isDark ? colors.surfaceAlt : colors.surface,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark ? Colors.white38 : colors.divider,
                      width: 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: kPrimaryColor, width: 1.5),
                  ),
                ),
                style: TextStyle(
                  color: isDark ? Colors.white : colors.onSurface,
                  fontSize: 13,
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),
          SizedBox(
            height: actionSize,
            width: actionSize,
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? colors.surfaceAlt : colors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? Colors.white38 : colors.divider,
                  width: 1,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: () {
                    context.navigateToNext(const StocktakeHistoryScreen());
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Center(
                    child: Icon(
                      Icons.history,
                      color: isDark ? Colors.white70 : colors.onSurface,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
