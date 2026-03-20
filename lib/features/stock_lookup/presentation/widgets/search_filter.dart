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

    // Mobile: scanner on left, filter on right
    // Tablet: search icon prefix, scanner on right
    if (isTablet) {
      return Row(
        children: [
          SizedBox(width: 12 * uiScale),
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
                  size: 22 * uiScale,
                ),
              ),
            ),
          ),
          if (onSearchModeChanged != null)
            SearchModeSelector(
              currentMode: searchMode,
              onModeChanged: onSearchModeChanged!,
            ),
          SizedBox(width: 8 * uiScale),
          IconButton(
            icon: Icon(
              Icons.qr_code_scanner,
              color: kPrimaryColor,
              size: 27 * uiScale,
            ),
            onPressed: onScannerTap,
          ),
          SizedBox(width: 10 * uiScale),
        ],
      );
    }

    // Mobile layout
    return Row(
      children: [
        SizedBox(width: 4 * uiScale),
        IconButton(
          icon: Icon(
            Icons.qr_code_scanner,
            color: kPrimaryColor,
            size: 24 * uiScale,
          ),
          onPressed: onScannerTap,
        ),
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
            ),
          ),
        ),
        if (onSearchModeChanged != null)
          SearchModeSelector(
            currentMode: searchMode,
            onModeChanged: onSearchModeChanged!,
          ),
        SizedBox(width: 4 * uiScale),
        IconButton(
          icon: Icon(
            Icons.filter_list,
            color: kPrimaryColor,
            size: 24 * uiScale,
          ),
          onPressed: onFilterTap,
        ),
        SizedBox(width: 4 * uiScale),
      ],
    );
  }
}
