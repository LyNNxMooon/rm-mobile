import 'package:flutter/material.dart';

import '../../../../constants/colors.dart';
import '../../../../constants/theme_colors.dart';
import '../../../../entities/vos/search_mode.dart';
import '../../../../utils/responsive_utils.dart';
import '../../../stock_lookup/presentation/widgets/search_mode_selector.dart';

class CustomerSearchFilterBar extends StatelessWidget {
  final ValueChanged<String>? onChanged;
  final VoidCallback? onFilterTap;
  final VoidCallback? onScannerTap;
  final VoidCallback? onAddTap;
  final SearchMode searchMode;
  final ValueChanged<SearchMode>? onSearchModeChanged;

  const CustomerSearchFilterBar({
    super.key,
    this.onChanged,
    this.onFilterTap,
    this.onScannerTap,
    this.onAddTap,
    this.searchMode = SearchMode.partial,
    this.onSearchModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final bool isDark = colors.isDark;
    final bool isTablet = MediaQuery.of(context).size.shortestSide >= 600;
    final bool useDesktopNav = context.useDesktopNav;
    final double textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
    final double uiScale = isTablet
        ? (1.0 + ((textScale - 1.0) * 0.35)).clamp(1.0, 1.2)
        : 1.0;
    final double fontSize = useDesktopNav ? 12 : 14;
    final double searchIconSize = useDesktopNav ? 18 : (isTablet ? 22 : 20) * uiScale;
    final double addIconSize = useDesktopNav ? 22 : (isTablet ? 28 : 26) * uiScale;
    final double leftPadding = useDesktopNav ? 14 : (isTablet ? 18 : 16) * uiScale;

    return Row(
      children: [
        SizedBox(width: leftPadding),
        Expanded(
          child: TextField(
            onChanged: onChanged,
            // Disable autocorrect and predictive text
            autocorrect: false,
            enableSuggestions: false,
            style: TextStyle(
              color: isDark ? Colors.white : colors.onSurface,
              fontSize: fontSize,
            ),
            decoration: InputDecoration(
              hintText: 'Search by barcode, name, company, phone, fax, email',
              hintStyle: TextStyle(
                color: isDark ? Colors.white70 : kThirdColor,
                fontSize: fontSize,
              ),
              border: InputBorder.none,
              isDense: true,
              prefixIcon: Icon(
                Icons.search,
                color: isDark ? Colors.white70 : Colors.blueGrey[700],
                size: searchIconSize,
              ),
            ),
          ),
        ),
        // Search Mode Selector next to add icon
        if (onSearchModeChanged != null)
          SearchModeSelector(
            currentMode: searchMode,
            onModeChanged: onSearchModeChanged!,
          ),
        SizedBox(width: useDesktopNav ? 2 : (isTablet ? 4 : 2) * uiScale),
        if (onAddTap != null)
          IconButton(
            onPressed: onAddTap,
            icon: Icon(
              Icons.add_circle,
              color: kPrimaryColor,
              size: addIconSize,
            ),
            tooltip: 'Create New Customer',
          ),
        SizedBox(width: useDesktopNav ? 4 : (isTablet ? 8 : 4) * uiScale),
      ],
    );
  }
}
