import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rmstock_scanner/entities/vos/filter_criteria.dart';
import 'package:rmstock_scanner/entities/vos/search_mode.dart';
import 'package:rmstock_scanner/features/stock_lookup/presentation/BLoC/stock_lookup_bloc.dart';
import 'package:rmstock_scanner/features/stock_lookup/presentation/BLoC/stock_lookup_events.dart';
import 'package:rmstock_scanner/features/stock_lookup/presentation/BLoC/stock_lookup_states.dart';
import 'package:rmstock_scanner/utils/navigation_extension.dart';

import '../../../../constants/colors.dart';
import '../../../../constants/global_widgets.dart';
import '../../../../constants/theme_colors.dart';
import '../../../../constants/txt_styles.dart';
import '../../../../utils/responsive_utils.dart';
import '../widgets/filter_breadcrumb.dart';
import '../widgets/filter_grid_item.dart';

/// Hierarchical filter levels
enum FilterLevel { department, cat1, cat2, cat3 }

class FilterScreen extends StatefulWidget {
  const FilterScreen({super.key});

  @override
  State<FilterScreen> createState() => _FilterScreenState();
}

class _FilterScreenState extends State<FilterScreen> {
  // Current drill-down level
  FilterLevel _currentLevel = FilterLevel.department;

  // Selected values at each level
  String? _selectedDept;
  String? _selectedCat1;
  String? _selectedCat2;
  String? _selectedCat3;

  // Search
  String _searchQuery = '';
  SearchMode _searchMode = SearchMode.partial;

  @override
  void initState() {
    super.initState();
    // Load filter options if not already loaded
    final state = context.read<FilterOptionsBloc>().state;
    if (state is! FiltersLoaded) {
      context.read<FilterOptionsBloc>().add(LoadFilterOptionsEvent());
    }

    // Restore previous selections if returning to filter screen
    final stockState = context.read<StockListBloc>().state;
    if (stockState is StockListLoaded && stockState.activeFilters != null) {
      final filters = stockState.activeFilters!;
      _selectedDept = filters.dept;
      _selectedCat1 = filters.cat1;
      _selectedCat2 = filters.cat2;
      _selectedCat3 = filters.cat3;

      // Set level based on deepest selection
      if (_selectedCat3 != null) {
        _currentLevel = FilterLevel.cat3;
      } else if (_selectedCat2 != null) {
        _currentLevel = FilterLevel.cat3;
      } else if (_selectedCat1 != null) {
        _currentLevel = FilterLevel.cat2;
      } else if (_selectedDept != null) {
        _currentLevel = FilterLevel.cat1;
      }
    }
  }

  void _onItemTap(String value) {
    setState(() {
      switch (_currentLevel) {
        case FilterLevel.department:
          _selectedDept = value;
          _currentLevel = FilterLevel.cat1;
          break;
        case FilterLevel.cat1:
          _selectedCat1 = value;
          _currentLevel = FilterLevel.cat2;
          break;
        case FilterLevel.cat2:
          _selectedCat2 = value;
          _currentLevel = FilterLevel.cat3;
          break;
        case FilterLevel.cat3:
          _selectedCat3 = value;
          // At deepest level, auto-apply
          _applyFilters();
          break;
      }
      _searchQuery = ''; // Clear search when drilling down
    });
  }

  void _onBreadcrumbTap(FilterLevel level) {
    setState(() {
      _currentLevel = level;
      _searchQuery = '';

      // Clear selections below the tapped level
      switch (level) {
        case FilterLevel.department:
          _selectedDept = null;
          _selectedCat1 = null;
          _selectedCat2 = null;
          _selectedCat3 = null;
          break;
        case FilterLevel.cat1:
          _selectedCat1 = null;
          _selectedCat2 = null;
          _selectedCat3 = null;
          break;
        case FilterLevel.cat2:
          _selectedCat2 = null;
          _selectedCat3 = null;
          break;
        case FilterLevel.cat3:
          _selectedCat3 = null;
          break;
      }
    });
  }

  void _applyFilters() {
    final criteria = FilterCriteria(
      dept: _selectedDept,
      cat1: _selectedCat1,
      cat2: _selectedCat2,
      cat3: _selectedCat3,
    );

    context.read<StockListBloc>().add(
      FetchFirstPageEvent(
        query: '',
        filters: criteria,
      ),
    );

    context.navigateBack();
  }

  void _clearAll() {
    setState(() {
      _currentLevel = FilterLevel.department;
      _selectedDept = null;
      _selectedCat1 = null;
      _selectedCat2 = null;
      _selectedCat3 = null;
      _searchQuery = '';
    });
  }

  List<String> _getFilteredItems(List<String> items) {
    if (_searchQuery.isEmpty) return items;

    final query = _searchQuery.toLowerCase();
    if (_searchMode == SearchMode.prefix) {
      return items.where((item) => item.toLowerCase().startsWith(query)).toList();
    }
    return items.where((item) => item.toLowerCase().contains(query)).toList();
  }

  String _getLevelTitle() {
    switch (_currentLevel) {
      case FilterLevel.department:
        return 'Select Department';
      case FilterLevel.cat1:
        return 'Select Category 1';
      case FilterLevel.cat2:
        return 'Select Category 2';
      case FilterLevel.cat3:
        return 'Select Category 3';
    }
  }

  bool get _hasAnySelection =>
      _selectedDept != null ||
      _selectedCat1 != null ||
      _selectedCat2 != null ||
      _selectedCat3 != null;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final bool isDark = colors.isDark;
    final bool isTablet = context.isTablet;
    final double textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
    final double uiScale = isTablet
        ? (1.0 + ((textScale - 1.0) * 0.35)).clamp(1.0, 1.2)
        : 1.0;

    return Scaffold(
      backgroundColor: isDark ? colors.bg : kBgColor,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 15),
            // App Bar
            _buildAppBar(colors, isDark, isTablet, uiScale),
            const SizedBox(height: 10),

            // Breadcrumb
            FilterBreadcrumb(
              currentLevel: _currentLevel,
              selectedDept: _selectedDept,
              selectedCat1: _selectedCat1,
              selectedCat2: _selectedCat2,
              selectedCat3: _selectedCat3,
              onLevelTap: _onBreadcrumbTap,
            ),

            Divider(
              indent: 15,
              endIndent: 15,
              thickness: 0.5,
              color: isDark ? Colors.white30 : kGreyColor,
            ),

            // Level Title
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 15,
                vertical: (isTablet ? 12 : 8) * uiScale,
              ),
              child: Row(
                children: [
                  Text(
                    _getLevelTitle(),
                    style: getSmartTitle(
                      color: isDark ? Colors.white : kThirdColor,
                      fontSize: (isTablet ? 18 : 16) * uiScale,
                    ),
                  ),
                ],
              ),
            ),

            // Grid Content
            Expanded(
              child: BlocBuilder<FilterOptionsBloc, FilterOptionsState>(
                builder: (context, state) {
                  if (state is FiltersLoading) {
                    return _buildLoading(colors, isDark, isTablet, uiScale);
                  }

                  if (state is FiltersLoaded) {
                    return _buildGrid(state, colors, isDark, isTablet, uiScale);
                  }

                  return _buildEmpty(colors, isDark);
                },
              ),
            ),

            // Search Bar
            _buildSearchBar(colors, isDark, isTablet, uiScale),

            // Apply Button
            _buildApplyButton(colors, isTablet, uiScale),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(AppThemeColors colors, bool isDark, bool isTablet, double uiScale) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Row(
        children: [
          // Back button
          InkWell(
            onTap: () => context.navigateBack(),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: EdgeInsets.all((isTablet ? 10 : 8) * uiScale),
              decoration: BoxDecoration(
                color: isDark
                    ? colors.surface.withOpacity(0.8)
                    : kSecondaryColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? Colors.white24 : kGreyColor.withOpacity(0.3),
                ),
              ),
              child: Icon(
                Icons.arrow_back_ios_new,
                size: (isTablet ? 20 : 18) * uiScale,
                color: isDark ? Colors.white : kThirdColor,
              ),
            ),
          ),
          const SizedBox(width: 15),

          // Title
          Expanded(
            child: Text(
              'Filter Stock',
              style: getSmartTitle(
                color: isDark ? Colors.white : kThirdColor,
                fontSize: (isTablet ? 22 : 20) * uiScale,
              ),
            ),
          ),

          // Clear button
          if (_hasAnySelection)
            TextButton(
              onPressed: _clearAll,
              child: Text(
                'Clear',
                style: TextStyle(
                  color: kPrimaryColor,
                  fontSize: (isTablet ? 16 : 14) * uiScale,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGrid(
    FiltersLoaded state,
    AppThemeColors colors,
    bool isDark,
    bool isTablet,
    double uiScale,
  ) {
    List<String> items;
    String? selectedValue;

    switch (_currentLevel) {
      case FilterLevel.department:
        items = state.departments;
        selectedValue = _selectedDept;
        break;
      case FilterLevel.cat1:
        items = state.cat1;
        selectedValue = _selectedCat1;
        break;
      case FilterLevel.cat2:
        items = state.cat2;
        selectedValue = _selectedCat2;
        break;
      case FilterLevel.cat3:
        items = state.cat3;
        selectedValue = _selectedCat3;
        break;
    }

    final filteredItems = _getFilteredItems(items);

    if (filteredItems.isEmpty) {
      return _buildEmpty(colors, isDark);
    }

    final crossAxisCount = isTablet ? 4 : 2;
    final childAspectRatio = isTablet ? 4.0 : 3.5;

    return GridView.builder(
      padding: EdgeInsets.symmetric(
        horizontal: 15,
        vertical: (isTablet ? 10 : 8) * uiScale,
      ),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: (isTablet ? 12 : 10) * uiScale,
        crossAxisSpacing: (isTablet ? 12 : 10) * uiScale,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: filteredItems.length,
      itemBuilder: (context, index) {
        final item = filteredItems[index];
        final isSelected = item == selectedValue;

        return FilterGridItem(
          label: item,
          isSelected: isSelected,
          onTap: () => _onItemTap(item),
          searchQuery: _searchQuery,
        );
      },
    );
  }

  Widget _buildLoading(AppThemeColors colors, bool isDark, bool isTablet, double uiScale) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Loading filter options...',
            style: getSmartTitle(
              color: isDark ? Colors.white : kThirdColor,
              fontSize: (isTablet ? 18 : 16) * uiScale,
            ),
          ),
          Padding(
            padding: EdgeInsets.only(
              top: 25,
              left: 80,
              right: 80,
              bottom: 5,
            ),
            child: ModernLoadingBar(),
          ),
          Text(
            'This may take a few seconds.',
            style: TextStyle(
              fontSize: (isTablet ? 13 : 11) * uiScale,
              color: isDark ? Colors.white70 : kGreyColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(AppThemeColors colors, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_open,
            size: 64,
            color: isDark ? Colors.white38 : kGreyColor.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No items found',
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.white70 : kGreyColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(AppThemeColors colors, bool isDark, bool isTablet, double uiScale) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 15,
        vertical: (isTablet ? 12 : 8) * uiScale,
      ),
      child: Container(
        height: (isTablet ? 56 : 50) * uiScale,
        decoration: BoxDecoration(
          color: isDark
              ? colors.surface.withOpacity(0.8)
              : kSecondaryColor,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isDark ? Colors.white24 : kGreyColor.withOpacity(0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? colors.cardShadow
                  : kThirdColor.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            SizedBox(width: 16 * uiScale),
            Icon(
              Icons.search,
              color: isDark ? Colors.white70 : Colors.blueGrey[700],
              size: (isTablet ? 22 : 20) * uiScale,
            ),
            SizedBox(width: 12 * uiScale),
            Expanded(
              child: TextField(
                onChanged: (value) => setState(() => _searchQuery = value),
                style: TextStyle(
                  color: isDark ? Colors.white : colors.onSurface,
                  fontSize: (isTablet ? 16 : 14) * uiScale,
                ),
                decoration: InputDecoration(
                  hintText: 'Search ${_getLevelTitle().replaceFirst('Select ', '')}...',
                  hintStyle: TextStyle(
                    color: isDark ? Colors.white54 : kGreyColor,
                    fontSize: (isTablet ? 16 : 14) * uiScale,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                ),
              ),
            ),
            // Search mode toggle
            InkWell(
              onTap: () {
                setState(() {
                  _searchMode = _searchMode == SearchMode.partial
                      ? SearchMode.prefix
                      : SearchMode.partial;
                });
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: (isTablet ? 10 : 8) * uiScale,
                  vertical: (isTablet ? 6 : 4) * uiScale,
                ),
                decoration: BoxDecoration(
                  color: kPrimaryColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _searchMode == SearchMode.partial ? 'Partial' : 'Starts-with',
                  style: TextStyle(
                    color: kPrimaryColor,
                    fontSize: (isTablet ? 12 : 10) * uiScale,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            SizedBox(width: 12 * uiScale),
          ],
        ),
      ),
    );
  }

  Widget _buildApplyButton(AppThemeColors colors, bool isTablet, double uiScale) {
    return Padding(
      padding: EdgeInsets.fromLTRB(15, 0, 15, (isTablet ? 24 : 20) * uiScale),
      child: SizedBox(
        width: double.infinity,
        height: (isTablet ? 54 : 50) * uiScale,
        child: ElevatedButton(
          onPressed: _applyFilters,
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimaryColor,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: Text(
            'Apply Filters',
            style: TextStyle(
              color: Colors.white,
              fontSize: (isTablet ? 18 : 16) * uiScale,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
