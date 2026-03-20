import 'package:flutter/material.dart';
import '../../../../constants/colors.dart';
import '../../../../constants/theme_colors.dart';
import '../../../../utils/text_highlight_utils.dart';

class FilterGridItem extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final String searchQuery;

  const FilterGridItem({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.searchQuery = '',
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

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isSelected
                ? kPrimaryColor
                : (isDark
                    ? Color.lerp(colors.surface, Colors.white, 0.06)
                    : kSecondaryColor),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? kPrimaryColor
                  : (isDark
                      ? Colors.white.withOpacity(0.18)
                      : kGreyColor.withOpacity(0.25)),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? kPrimaryColor.withOpacity(0.3)
                    : (isDark
                        ? Colors.black.withOpacity(0.2)
                        : kThirdColor.withOpacity(0.05)),
                blurRadius: isSelected ? 8 : 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: EdgeInsets.symmetric(
            horizontal: (isTablet ? 14 : 12) * uiScale,
            vertical: (isTablet ? 10 : 8) * uiScale,
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildLabel(colors, isDark, isTablet, uiScale),
              ),
              Icon(
                Icons.chevron_right,
                size: (isTablet ? 22 : 18) * uiScale,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white54 : kGreyColor),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(AppThemeColors colors, bool isDark, bool isTablet, double uiScale) {
    final textColor = isSelected
        ? Colors.white
        : (isDark ? Colors.white : kThirdColor);

    final fontSize = (isTablet ? 15 : 13) * uiScale;

    if (searchQuery.isNotEmpty) {
      return HighlightedText(
        text: label,
        query: searchQuery,
        style: TextStyle(
          color: textColor,
          fontSize: fontSize,
          fontWeight: FontWeight.w500,
        ),
        highlightColor: isSelected
            ? Colors.white.withOpacity(0.3)
            : kPrimaryColor.withOpacity(0.3),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      );
    }

    return Text(
      label,
      style: TextStyle(
        color: textColor,
        fontSize: fontSize,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}
