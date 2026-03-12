import 'package:flutter/material.dart';

import '../../../../constants/colors.dart';
import '../../../../entities/vos/search_mode.dart';
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
    final bool isTablet = MediaQuery.of(context).size.shortestSide >= 600;
    final double textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
    final double uiScale = isTablet
        ? (1.0 + ((textScale - 1.0) * 0.35)).clamp(1.0, 1.2)
        : 1.0;

    return Row(
      children: [
        SizedBox(width: (isTablet ? 18 : 16) * uiScale),
        Expanded(
          child: TextField(
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: 'Search customers...',
              hintStyle: const TextStyle(color: kThirdColor, fontSize: 14),
              border: InputBorder.none,
              isDense: true,
              prefixIcon: Icon(
                Icons.search,
                color: kGreyColor,
                size: (isTablet ? 22 : 20) * uiScale,
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
        SizedBox(width: (isTablet ? 4 : 2) * uiScale),
        if (onAddTap != null)
          IconButton(
            onPressed: onAddTap,
            icon: Icon(
              Icons.add_circle,
              color: kPrimaryColor,
              size: (isTablet ? 28 : 26) * uiScale,
            ),
            tooltip: 'Create New Customer',
          ),
        SizedBox(width: (isTablet ? 8 : 4) * uiScale),
      ],
    );
  }
}
