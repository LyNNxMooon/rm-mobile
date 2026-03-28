import 'package:flutter/material.dart';
import '../../../../constants/colors.dart';
import '../../../../constants/theme_colors.dart';
import '../../../../utils/responsive_utils.dart';
import '../screens/filter_screen.dart';

class FilterBreadcrumb extends StatelessWidget {
  final FilterLevel currentLevel;
  final String? selectedDept;
  final String? selectedCat1;
  final String? selectedCat2;
  final String? selectedCat3;
  final ValueChanged<FilterLevel> onLevelTap;

  const FilterBreadcrumb({
    super.key,
    required this.currentLevel,
    this.selectedDept,
    this.selectedCat1,
    this.selectedCat2,
    this.selectedCat3,
    required this.onLevelTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final bool isDark = colors.isDark;
    final bool isTablet = context.isTablet;
    final double textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
    final double uiScale = isTablet
        ? (1.0 + ((textScale - 1.0) * 0.35)).clamp(1.0, 1.2)
        : 1.0;

    final crumbs = _buildCrumbs();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(
        horizontal: 15,
        vertical: (isTablet ? 10 : 8) * uiScale,
      ),
      child: Row(
        children: [
          for (int i = 0; i < crumbs.length; i++) ...[
            _buildCrumbItem(
              context,
              crumbs[i],
              i == crumbs.length - 1,
              colors,
              isDark,
              isTablet,
              uiScale,
            ),
            if (i < crumbs.length - 1)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: (isTablet ? 8 : 6) * uiScale),
                child: Icon(
                  Icons.chevron_right,
                  size: (isTablet ? 18 : 16) * uiScale,
                  color: isDark ? Colors.white38 : kGreyColor,
                ),
              ),
          ],
        ],
      ),
    );
  }

  List<_CrumbData> _buildCrumbs() {
    final crumbs = <_CrumbData>[];

    // Always show "All" as root
    crumbs.add(_CrumbData(
      label: 'All',
      level: FilterLevel.department,
      isActive: currentLevel == FilterLevel.department && selectedDept == null,
    ));

    // Department
    if (selectedDept != null) {
      crumbs.add(_CrumbData(
        label: _truncate(selectedDept!, 15),
        level: FilterLevel.cat1,
        isActive: currentLevel == FilterLevel.cat1,
      ));
    }

    // Cat1
    if (selectedCat1 != null) {
      crumbs.add(_CrumbData(
        label: _truncate(selectedCat1!, 15),
        level: FilterLevel.cat2,
        isActive: currentLevel == FilterLevel.cat2,
      ));
    }

    // Cat2
    if (selectedCat2 != null) {
      crumbs.add(_CrumbData(
        label: _truncate(selectedCat2!, 15),
        level: FilterLevel.cat3,
        isActive: currentLevel == FilterLevel.cat3,
      ));
    }

    // Cat3
    if (selectedCat3 != null) {
      crumbs.add(_CrumbData(
        label: _truncate(selectedCat3!, 15),
        level: FilterLevel.cat3,
        isActive: true,
      ));
    }

    return crumbs;
  }

  String _truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  Widget _buildCrumbItem(
    BuildContext context,
    _CrumbData crumb,
    bool isLast,
    AppThemeColors colors,
    bool isDark,
    bool isTablet,
    double uiScale,
  ) {
    final isClickable = !isLast;

    return InkWell(
      onTap: isClickable ? () => onLevelTap(crumb.level) : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: (isTablet ? 12 : 10) * uiScale,
          vertical: (isTablet ? 8 : 6) * uiScale,
        ),
        decoration: BoxDecoration(
          color: crumb.isActive
              ? kPrimaryColor.withOpacity(0.15)
              : (isClickable
                  ? (isDark
                      ? colors.surface.withOpacity(0.5)
                      : kSecondaryColor.withOpacity(0.8))
                  : Colors.transparent),
          borderRadius: BorderRadius.circular(8),
          border: crumb.isActive
              ? Border.all(color: kPrimaryColor.withOpacity(0.5))
              : null,
        ),
        child: Text(
          crumb.label,
          style: TextStyle(
            color: crumb.isActive
                ? kPrimaryColor
                : (isClickable
                    ? (isDark ? Colors.white70 : kThirdColor)
                    : (isDark ? Colors.white38 : kGreyColor)),
            fontSize: (isTablet ? 14 : 12) * uiScale,
            fontWeight: crumb.isActive ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _CrumbData {
  final String label;
  final FilterLevel level;
  final bool isActive;

  _CrumbData({
    required this.label,
    required this.level,
    required this.isActive,
  });
}
