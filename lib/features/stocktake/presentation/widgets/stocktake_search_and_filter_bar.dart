import 'package:flutter/material.dart';
import 'package:rmmobile/features/stocktake/presentation/screens/stocktake_history_screen.dart';
import 'package:rmmobile/utils/navigation_extension.dart';
import 'package:rmmobile/utils/responsive_utils.dart';

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
    final bool useDesktopNav = context.useDesktopNav;
    final bool isTablet = MediaQuery.of(context).size.shortestSide >= 600;
    final double textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
    final double uiScale = isTablet
        ? (1.0 + ((textScale - 1.0) * 0.35)).clamp(1.0, 1.2)
        : 1.0;
    final double actionSize = useDesktopNav ? 36 : (isTablet ? 48 : 42) * uiScale;
    final double hintFontSize = useDesktopNav ? 12.0 : 13.0;
    final double iconSize = useDesktopNav ? 18.0 : 20.0;
    final double borderRadius = useDesktopNav ? 8.0 : 12.0;
    final double horizontalPadding = useDesktopNav ? 12.0 : 15.0;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: useDesktopNav ? 800 : double.infinity),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
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
                      hintText: "Search barcode or description...",
                      hintStyle: TextStyle(
                        color: isDark ? Colors.white70 : colors.onSurfaceMuted,
                        fontSize: hintFontSize,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: isDark ? Colors.white70 : kPrimaryColor,
                        size: iconSize,
                      ),
                      filled: true,
                      fillColor: isDark ? colors.surfaceAlt : colors.surface,
                      contentPadding: EdgeInsets.symmetric(horizontal: useDesktopNav ? 10 : 12),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(borderRadius),
                        borderSide: BorderSide(
                          color: isDark ? Colors.white38 : colors.divider,
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(borderRadius),
                        borderSide: BorderSide(color: kPrimaryColor, width: 1.5),
                      ),
                    ),
                    style: TextStyle(
                      color: isDark ? Colors.white : colors.onSurface,
                      fontSize: hintFontSize,
                    ),
                  ),
                ),
              ),

              SizedBox(width: useDesktopNav ? 6 : 8),
              SizedBox(
                height: actionSize,
                width: actionSize,
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? colors.surfaceAlt : colors.surface,
                    borderRadius: BorderRadius.circular(borderRadius),
                    border: Border.all(
                      color: isDark ? Colors.white38 : colors.divider,
                      width: 1,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(borderRadius),
                    child: InkWell(
                      onTap: () {
                        context.navigateToNext(const StocktakeHistoryScreen());
                      },
                      borderRadius: BorderRadius.circular(borderRadius),
                      child: Center(
                        child: Icon(
                          Icons.history,
                          color: isDark ? Colors.white70 : colors.onSurface,
                          size: iconSize,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
