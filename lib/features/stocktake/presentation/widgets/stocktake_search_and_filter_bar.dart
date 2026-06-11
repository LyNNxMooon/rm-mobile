import 'package:flutter/material.dart';
import 'package:rmmobile/features/stocktake/presentation/screens/stocktake_history_screen.dart';
import 'package:rmmobile/utils/navigation_extension.dart';
import 'package:rmmobile/utils/responsive_utils.dart';

import '../../../../constants/colors.dart';
import '../../../../constants/theme_colors.dart';

class StocktakeSearchAndFilterBar extends StatefulWidget {
  final ValueChanged<String>? onChanged;
  final VoidCallback? onFilterTap;

  const StocktakeSearchAndFilterBar({
    super.key,
    this.onChanged,
    this.onFilterTap,
  });

  @override
  State<StocktakeSearchAndFilterBar> createState() =>
      _StocktakeSearchAndFilterBarState();
}

class _StocktakeSearchAndFilterBarState
    extends State<StocktakeSearchAndFilterBar> {
  final FocusNode _focusNode = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (_focused != _focusNode.hasFocus) {
        setState(() => _focused = _focusNode.hasFocus);
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

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
    final double containerHeight = useDesktopNav ? 36 : (isTablet ? 46 : 40) * uiScale;
    final double hintFontSize = useDesktopNav ? 12.0 : 13.0;
    final double iconSize = useDesktopNav ? 18.0 : 20.0;
    final double horizontalPadding = useDesktopNav ? 12.0 : 15.0;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: useDesktopNav ? 800 : double.infinity),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: containerHeight,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black : Colors.white,
                    borderRadius: BorderRadius.circular(containerHeight / 2),
                    border: Border.all(
                      color: _focused
                          ? kPrimaryColor
                          : (isDark
                              ? Colors.white24
                              : kPrimaryColor.withOpacity(0.5)),
                      width: _focused ? 2 : 1,
                    ),
                  ),
                  child: Center(
                    child: TextField(
                      focusNode: _focusNode,
                      onChanged: widget.onChanged,
                      // Disable autocorrect and predictive text
                      autocorrect: false,
                      enableSuggestions: false,
                      textAlignVertical: TextAlignVertical.center,
                      style: TextStyle(
                        color: isDark ? Colors.white : colors.onSurface,
                        fontSize: hintFontSize,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
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
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: useDesktopNav ? 10 : 12,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // History icon - only on mobile/tablet, not on desktop
              if (!useDesktopNav) ...[
                SizedBox(width: isTablet ? 10 : 8),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      context.navigateToNext(const StocktakeHistoryScreen());
                    },
                    customBorder: const CircleBorder(),
                    child: Container(
                      width: containerHeight,
                      height: containerHeight,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark
                            ? const Color(0xFF212121)
                            : kPrimaryColor.withOpacity(0.08),
                      ),
                      child: Icon(
                        Icons.history,
                        color: kPrimaryColor,
                        size: isTablet ? 22 : 20,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
