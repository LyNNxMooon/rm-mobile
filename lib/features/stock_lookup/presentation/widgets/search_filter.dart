import 'package:flutter/material.dart';
import '../../../../constants/colors.dart';
import '../../../../constants/theme_colors.dart';
import '../../../../entities/vos/search_mode.dart';
import 'search_mode_selector.dart';

class SearchFilterBar extends StatelessWidget {
  final ValueChanged<String>? onChanged;
  final VoidCallback? onFilterTap;
  final VoidCallback? onScannerTap;
  final SearchMode searchMode;
  final ValueChanged<SearchMode>? onSearchModeChanged;

  const SearchFilterBar({
    super.key,
    this.onChanged,
    this.onFilterTap,
    this.onScannerTap,
    this.searchMode = SearchMode.partial,
    this.onSearchModeChanged,
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

    return Row(
      children: [
        SizedBox(width: (isTablet ? 12 : 10) * uiScale),
        Expanded(
          child: TextField(
            onChanged: onChanged,
            style: TextStyle(
              color: isDark ? Colors.white : colors.onSurface,
              fontSize: 14,
            ),
            decoration: InputDecoration(
              hintText: 'Search by barcode, description, custom1, or custom2',
              hintStyle: TextStyle(
                color: isDark ? Colors.white70 : kThirdColor,
                fontSize: 14,
              ),
              border: InputBorder.none,
              isDense: true,
              prefixIcon: Icon(
                Icons.search,
                color: isDark ? Colors.white70 : Colors.blueGrey[700],
                size: (isTablet ? 22 : 20) * uiScale,
              ),
            ),
          ),
        ),
        if (onSearchModeChanged != null)
          SearchModeSelector(
            currentMode: searchMode,
            onModeChanged: onSearchModeChanged!,
          ),
        SizedBox(width: (isTablet ? 8 : 4) * uiScale),
        IconButton(
          icon: Icon(
            Icons.qr_code_scanner,
            color: kPrimaryColor,
            size: (isTablet ? 27 : 24) * uiScale,
          ),
          onPressed: onScannerTap,
        ),
        SizedBox(width: (isTablet ? 10 : 8) * uiScale),
      ],
    );
  }
}
