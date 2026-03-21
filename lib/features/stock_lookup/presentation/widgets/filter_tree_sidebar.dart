import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rmstock_scanner/entities/vos/filter_criteria.dart';
import 'package:rmstock_scanner/features/stock_lookup/presentation/BLoC/stock_lookup_bloc.dart';
import 'package:rmstock_scanner/features/stock_lookup/presentation/BLoC/stock_lookup_events.dart';
import 'package:rmstock_scanner/features/stock_lookup/presentation/BLoC/stock_lookup_states.dart';

import '../../../../constants/colors.dart';
import '../../../../constants/theme_colors.dart';
import '../../../../constants/txt_styles.dart';

/// Windows File Explorer-style tree sidebar for tablet filter navigation
class FilterTreeSidebar extends StatefulWidget {
  final VoidCallback? onFilterApplied;

  const FilterTreeSidebar({
    super.key,
    this.onFilterApplied,
  });

  @override
  State<FilterTreeSidebar> createState() => _FilterTreeSidebarState();
}

class _FilterTreeSidebarState extends State<FilterTreeSidebar> {
  // Expansion state
  String? _expandedDept;
  String? _expandedCat1;
  String? _expandedCat2;

  // Selected values
  String? _selectedDept;
  String? _selectedCat1;
  String? _selectedCat2;
  String? _selectedCat3;

  @override
  void initState() {
    super.initState();
    // Restore previous selections
    final stockState = context.read<StockListBloc>().state;
    if (stockState is StockListLoaded && stockState.activeFilters != null) {
      final filters = stockState.activeFilters!;
      _selectedDept = filters.dept;
      _selectedCat1 = filters.cat1;
      _selectedCat2 = filters.cat2;
      _selectedCat3 = filters.cat3;

      // Auto-expand to show selections
      _expandedDept = _selectedDept;
      _expandedCat1 = _selectedCat1;
      _expandedCat2 = _selectedCat2;
    }
  }

  void _applyFilter({
    String? dept,
    String? cat1,
    String? cat2,
    String? cat3,
  }) {
    setState(() {
      _selectedDept = dept;
      _selectedCat1 = cat1;
      _selectedCat2 = cat2;
      _selectedCat3 = cat3;
    });

    final criteria = FilterCriteria(
      dept: dept,
      cat1: cat1,
      cat2: cat2,
      cat3: cat3,
    );

    context.read<StockListBloc>().add(
      FetchFirstPageEvent(
        query: '',
        filters: criteria,
      ),
    );

    widget.onFilterApplied?.call();
  }

  void _clearFilters() {
    setState(() {
      _expandedDept = null;
      _expandedCat1 = null;
      _expandedCat2 = null;
      _selectedDept = null;
      _selectedCat1 = null;
      _selectedCat2 = null;
      _selectedCat3 = null;
    });

    context.read<StockListBloc>().add(
      FetchFirstPageEvent(
        query: '',
        filters: null,
      ),
    );

    widget.onFilterApplied?.call();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final bool isDark = colors.isDark;
    final double textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
    final double uiScale = (1.0 + ((textScale - 1.0) * 0.35)).clamp(1.0, 1.2);

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Color.lerp(colors.surface, Colors.white, 0.03)
            : kSecondaryColor,
        border: Border(
          right: BorderSide(
            color: isDark ? Colors.white12 : kGreyColor.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Top spacing to align with appbar
          const SizedBox(height: 25),

          // Header
          _buildHeader(colors, isDark, uiScale),

          // Tree content
          Expanded(
            child: BlocBuilder<FilterOptionsBloc, FilterOptionsState>(
              builder: (context, state) {
                if (state is FiltersLoading) {
                  return const Center(
                    child: CircularProgressIndicator(color: kPrimaryColor),
                  );
                }

                if (state is FiltersLoaded) {
                  return _buildTree(state, colors, isDark, uiScale);
                }

                return Center(
                  child: Text(
                    'No filters available',
                    style: TextStyle(
                      color: isDark ? Colors.white54 : kGreyColor,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(AppThemeColors colors, bool isDark, double uiScale) {
    final hasSelection = _selectedDept != null ||
        _selectedCat1 != null ||
        _selectedCat2 != null ||
        _selectedCat3 != null;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 16 * uiScale,
        vertical: 14 * uiScale,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? colors.surface.withOpacity(0.5)
            : kBgColor,
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.white12 : kGreyColor.withOpacity(0.15),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.folder_outlined,
            size: 20 * uiScale,
            color: kPrimaryColor,
          ),
          SizedBox(width: 10 * uiScale),
          Expanded(
            child: Text(
              'Dept/Cats',
              style: getSmartTitle(
                color: kPrimaryColor,
                fontSize: 16,
              ),
            ),
          ),
          if (hasSelection)
            InkWell(
              onTap: _clearFilters,
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: EdgeInsets.all(4 * uiScale),
                child: Text(
                  'Clear',
                  style: TextStyle(
                    color: kPrimaryColor,
                    fontSize: 13 * uiScale,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTree(
    FiltersLoaded state,
    AppThemeColors colors,
    bool isDark,
    double uiScale,
  ) {
    return ListView(
      padding: EdgeInsets.symmetric(vertical: 8 * uiScale),
      children: [
        // "All Items" option
        _buildTreeItem(
          label: 'All Items',
          icon: Icons.inventory_2_outlined,
          level: 0,
          isSelected: _selectedDept == null,
          onTap: () => _applyFilter(),
          colors: colors,
          isDark: isDark,
          uiScale: uiScale,
        ),

        // Departments
        ...state.departments.map((dept) {
          final isExpanded = _expandedDept == dept;
          final isSelected = _selectedDept == dept && _selectedCat1 == null;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTreeItem(
                label: dept,
                icon: isExpanded ? Icons.folder_open : Icons.folder_outlined,
                level: 0,
                isSelected: isSelected,
                isExpanded: isExpanded,
                hasChildren: true,
                onTap: () => _applyFilter(dept: dept),
                onExpandTap: () {
                  setState(() {
                    if (_expandedDept == dept) {
                      _expandedDept = null;
                      _expandedCat1 = null;
                      _expandedCat2 = null;
                    } else {
                      _expandedDept = dept;
                      _expandedCat1 = null;
                      _expandedCat2 = null;
                    }
                  });
                },
                colors: colors,
                isDark: isDark,
                uiScale: uiScale,
              ),

              // Cat1 children
              if (isExpanded)
                ...state.cat1.map((cat1) {
                  final isCat1Expanded = _expandedCat1 == cat1;
                  final isCat1Selected = _selectedDept == dept &&
                      _selectedCat1 == cat1 &&
                      _selectedCat2 == null;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTreeItem(
                        label: cat1,
                        icon: isCat1Expanded
                            ? Icons.folder_open
                            : Icons.folder_outlined,
                        level: 1,
                        isSelected: isCat1Selected,
                        isExpanded: isCat1Expanded,
                        hasChildren: true,
                        onTap: () => _applyFilter(dept: dept, cat1: cat1),
                        onExpandTap: () {
                          setState(() {
                            if (_expandedCat1 == cat1) {
                              _expandedCat1 = null;
                              _expandedCat2 = null;
                            } else {
                              _expandedCat1 = cat1;
                              _expandedCat2 = null;
                            }
                          });
                        },
                        colors: colors,
                        isDark: isDark,
                        uiScale: uiScale,
                      ),

                      // Cat2 children
                      if (isCat1Expanded)
                        ...state.cat2.map((cat2) {
                          final isCat2Expanded = _expandedCat2 == cat2;
                          final isCat2Selected = _selectedDept == dept &&
                              _selectedCat1 == cat1 &&
                              _selectedCat2 == cat2 &&
                              _selectedCat3 == null;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildTreeItem(
                                label: cat2,
                                icon: isCat2Expanded
                                    ? Icons.folder_open
                                    : Icons.folder_outlined,
                                level: 2,
                                isSelected: isCat2Selected,
                                isExpanded: isCat2Expanded,
                                hasChildren: true,
                                onTap: () => _applyFilter(
                                  dept: dept,
                                  cat1: cat1,
                                  cat2: cat2,
                                ),
                                onExpandTap: () {
                                  setState(() {
                                    _expandedCat2 =
                                        _expandedCat2 == cat2 ? null : cat2;
                                  });
                                },
                                colors: colors,
                                isDark: isDark,
                                uiScale: uiScale,
                              ),

                              // Cat3 children (leaf nodes)
                              if (isCat2Expanded)
                                ...state.cat3.map((cat3) {
                                  final isCat3Selected = _selectedDept == dept &&
                                      _selectedCat1 == cat1 &&
                                      _selectedCat2 == cat2 &&
                                      _selectedCat3 == cat3;

                                  return _buildTreeItem(
                                    label: cat3,
                                    icon: Icons.label_outline,
                                    level: 3,
                                    isSelected: isCat3Selected,
                                    hasChildren: false,
                                    onTap: () => _applyFilter(
                                      dept: dept,
                                      cat1: cat1,
                                      cat2: cat2,
                                      cat3: cat3,
                                    ),
                                    colors: colors,
                                    isDark: isDark,
                                    uiScale: uiScale,
                                  );
                                }),
                            ],
                          );
                        }),
                    ],
                  );
                }),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildTreeItem({
    required String label,
    required IconData icon,
    required int level,
    required bool isSelected,
    bool isExpanded = false,
    bool hasChildren = false,
    required VoidCallback onTap,
    VoidCallback? onExpandTap,
    required AppThemeColors colors,
    required bool isDark,
    required double uiScale,
  }) {
    final leftPadding = 8.0 + (level * 16.0);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 8 * uiScale,
        vertical: 5 * uiScale,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            onTap();
            if (hasChildren && onExpandTap != null) {
              onExpandTap();
            }
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: EdgeInsets.only(
              left: leftPadding * uiScale,
              right: 12 * uiScale,
              top: 16 * uiScale,
              bottom: 16 * uiScale,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? kPrimaryColor.withOpacity(isDark ? 0.3 : 0.18)
                  : (isDark
                      ? colors.surface.withOpacity(0.5)
                      : Colors.white),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected
                    ? kPrimaryColor.withOpacity(0.6)
                    : (isDark ? Colors.white24 : kGreyColor.withOpacity(0.25)),
                width: isSelected ? 1.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withOpacity(0.3)
                      : Colors.black.withOpacity(0.1),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                // Icon
                Container(
                  padding: EdgeInsets.all(6 * uiScale),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? kPrimaryColor.withOpacity(0.2)
                        : (isDark
                            ? Colors.white.withOpacity(0.1)
                            : kGreyColor.withOpacity(0.1)),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    icon,
                    size: 16 * uiScale,
                    color: isSelected
                        ? kPrimaryColor
                        : (isDark ? Colors.white70 : kThirdColor.withOpacity(0.7)),
                  ),
                ),
                SizedBox(width: 10 * uiScale),

                // Label
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isSelected
                          ? kPrimaryColor
                          : (isDark ? Colors.white : kThirdColor),
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // Expand/collapse arrow (for items with children)
                if (hasChildren)
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_down
                        : Icons.keyboard_arrow_right,
                    size: 20 * uiScale,
                    color: isSelected
                        ? kPrimaryColor
                        : (isDark ? Colors.white54 : kGreyColor),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
