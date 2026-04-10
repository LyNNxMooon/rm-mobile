import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rmmobile/features/stock_lookup/presentation/BLoC/stock_lookup_bloc.dart';
import 'package:rmmobile/features/stock_lookup/presentation/BLoC/stock_lookup_states.dart';
import 'package:rmmobile/utils/navigation_extension.dart';

import '../../../../constants/colors.dart';
import '../../../../constants/global_widgets.dart';
import '../../../../constants/theme_colors.dart';
import '../../../../constants/txt_styles.dart';
import '../../../../entities/vos/filter_criteria.dart';
import '../../../../utils/dialog_size_utils.dart';
import '../../../../utils/responsive_utils.dart';
import '../BLoC/stock_lookup_events.dart';

class StocklookupFilterDialog extends StatefulWidget {
  const StocklookupFilterDialog({super.key});

  @override
  State<StocklookupFilterDialog> createState() =>
      _StocklookupFilterDialogState();
}

class _StocklookupFilterDialogState extends State<StocklookupFilterDialog> {
  @override
  void initState() {
    final currentState = context.read<StockListBloc>().state;

    if (currentState is StockListLoaded && currentState.activeFilters != null) {
      final filters = currentState.activeFilters!;
      selectedDept = filters.dept;
      selectedCat1 = filters.cat1;
      selectedCat2 = filters.cat2;
      selectedCat3 = filters.cat3;
      super.initState();
    }
  }

  String? selectedDept;
  String? selectedCat1;
  String? selectedCat2;
  String? selectedCat3;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final media = MediaQuery.of(context);
    final bool isTablet = context.isTablet;
    final bool isPortrait = context.isPortrait;
    final double textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
    final double uiScale = isTablet
        ? (1.0 + ((textScale - 1.0) * 0.35)).clamp(1.0, 1.2)
        : 1.0;
    final EdgeInsets insetPadding = isTablet
        ? EdgeInsets.symmetric(
            horizontal: isPortrait ? 36 : 72,
            vertical: 24,
          )
        : dialogInsetPadding(context);
    final double dialogMaxWidth = isTablet
        ? (media.size.width * (isPortrait ? 0.9 : 0.78)).clamp(520.0, 980.0)
        : 400.0;
    final double panelPadding = (isTablet ? 28 : 24) * uiScale;
    final double sectionGap = (isTablet ? 14 : 12) * uiScale;
    final double buttonHeight = (isTablet ? 54 : 50) * uiScale;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: insetPadding,
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(
          maxWidth: dialogMaxWidth,
          maxHeight: isTablet ? 720 : 650,
        ),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: colors.cardShadow,
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: panelPadding,
                vertical: (isTablet ? 22 : 20) * uiScale,
              ),
              decoration: BoxDecoration(
                gradient: colors.heroGradient,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10),
                ),
                border: Border(
                  bottom: BorderSide(color: kPrimaryColor.withOpacity(0.1)),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Filter Stock",
                    style: getSmartTitle(
                      color: colors.onHero,
                      fontSize: 20,
                    ),
                  ),
                  InkWell(
                    onTap: () => context.navigateBack(),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: EdgeInsets.all((isTablet ? 8 : 6) * uiScale),
                      decoration: BoxDecoration(
                        color: colors.onHero.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close,
                        size: 18,
                        color: colors.onHero,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            BlocBuilder<FilterOptionsBloc, FilterOptionsState>(
              builder: (context, state) {
                List<String> depts = [];
                List<String> c1 = [];
                List<String> c2 = [];
                List<String> c3 = [];

                if (state is FiltersLoaded) {
                  depts = state.departments;
                  c1 = state.cat1;
                  c2 = state.cat2;
                  c3 = state.cat3;

                  //Validate selections against current shopfront
                  if (!depts.contains(selectedDept)) selectedDept = null;
                  if (!c1.contains(selectedCat1)) selectedCat1 = null;
                  if (!c2.contains(selectedCat2)) selectedCat2 = null;
                  if (!c3.contains(selectedCat3)) selectedCat3 = null;
                }

                if (state is FiltersLoading) {
                  return Flexible(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            "Loading your filter options...",
                            style: getSmartTitle(
                              color: colors.onSurface,
                              fontSize: 16,
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(
                              top: (isTablet ? 30 : 25) * uiScale,
                              left: (isTablet ? 70 : 60) * uiScale,
                              right: (isTablet ? 70 : 60) * uiScale,
                              bottom: 5,
                            ),
                            child: ModernLoadingBar(),
                          ),
                          Text(
                            "This may take a few seconds.",
                            style: TextStyle(fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(panelPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader("Classifications", colors),
                        SizedBox(height: sectionGap),
                        _buildDropdown(
                          "Department",
                          selectedDept,
                          depts,
                          (val) => setState(() => selectedDept = val),
                          colors,
                        ),
                        SizedBox(height: sectionGap),
                        _buildDropdown(
                          "Category 1",
                          selectedCat1,
                          c1,
                          (val) => setState(() => selectedCat1 = val),
                          colors,
                        ),
                        SizedBox(height: sectionGap),
                        _buildDropdown(
                          "Category 2",
                          selectedCat2,
                          c2,
                          (val) => setState(() => selectedCat2 = val),
                          colors,
                        ),
                        SizedBox(height: sectionGap),
                        _buildDropdown(
                          "Category 3",
                          selectedCat3,
                          c3,
                          (val) => setState(() => selectedCat3 = val),
                          colors,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            Padding(
              padding: EdgeInsets.all(panelPadding),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: buttonHeight,
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            selectedDept = null;
                            selectedCat1 = null;
                            selectedCat2 = null;
                            selectedCat3 = null;
                          });
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(color: colors.divider),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          "Reset",
                          style: TextStyle(color: colors.onSurfaceMuted),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: (isTablet ? 18 : 16) * uiScale),

                  Expanded(
                    child: SizedBox(
                      height: buttonHeight,
                      child: ElevatedButton(
                        onPressed: () {
                          final criteria = FilterCriteria(
                            dept: selectedDept,
                            cat1: selectedCat1,
                            cat2: selectedCat2,
                            cat3: selectedCat3,
                          );

                          // 2. Dispatch Event to Main Bloc
                          // Note: We reset query/sort to defaults or keep them.
                          // Usually applying heavy filters resets search query to empty.
                          context.read<StockListBloc>().add(
                            FetchFirstPageEvent(
                              query:
                                  "", // Reset text search when applying heavy filters? Or keep it?
                              // If you want to keep it, you need to pass it in constructor or
                              // access it via context if stored in a provider.
                              // For now, let's reset query for clean results.
                              filters: criteria,
                            ),
                          );

                          context.navigateBack();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          "Apply Filters",
                          style: TextStyle(
                            color: colors.onHero,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, AppThemeColors colors) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: kPrimaryColor.withOpacity(0.8),
        letterSpacing: 1.1,
      ),
    );
  }

  Widget _buildDropdown(
    String hint,
    String? value,
    List<String> items,
    Function(String?) onChanged,
    AppThemeColors colors,
  ) {
    return Container(
      constraints: const BoxConstraints(minHeight: 46),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.divider),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          dropdownColor: colors.surface,
          hint: Text(
            hint,
            style: TextStyle(color: colors.onSurfaceMuted, fontSize: 14),
          ),
          isExpanded: true,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: colors.onSurfaceMuted,
          ),
          onChanged: onChanged,

          items: items
              .map(
                (e) => DropdownMenuItem(
                  value: e,
                  child: Text(
                    e,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
