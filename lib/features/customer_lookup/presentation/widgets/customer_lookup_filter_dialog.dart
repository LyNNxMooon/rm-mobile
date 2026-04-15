import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rmmobile/utils/navigation_extension.dart';

import '../../../../constants/colors.dart';
import '../../../../constants/theme_colors.dart';
import '../../../../constants/global_widgets.dart';
import '../../../../constants/txt_styles.dart';
import '../../../../entities/vos/filter_criteria.dart';
import '../../../../utils/dialog_size_utils.dart';
import '../BLoC/customer_lookup_bloc.dart';
import '../BLoC/customer_lookup_events.dart';
import '../BLoC/customer_lookup_states.dart';

class CustomerLookupFilterDialog extends StatefulWidget {
  const CustomerLookupFilterDialog({super.key});

  @override
  State<CustomerLookupFilterDialog> createState() =>
      _CustomerLookupFilterDialogState();
}

class _CustomerLookupFilterDialogState
    extends State<CustomerLookupFilterDialog> {
  String? selectedState;
  String? selectedSuburb;
  String? selectedPostcode;

  @override
  void initState() {
    final currentState = context.read<CustomerListBloc>().state;

    if (currentState is CustomerListLoaded && currentState.activeFilters != null) {
      final filters = currentState.activeFilters!;
      selectedState = filters.state;
      selectedSuburb = filters.suburb;
      selectedPostcode = filters.postcode;
    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final media = MediaQuery.of(context);
    final bool isTablet = media.size.shortestSide >= 600;
    final bool isPortrait = media.orientation == Orientation.portrait;
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
          maxHeight: isTablet ? 620 : 560,
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
                    'Filter Customers',
                    style: getSmartTitle(color: colors.onHero, fontSize: 20),
                  ),
                  InkWell(
                    onTap: () => context.navigateBack(),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: EdgeInsets.all((isTablet ? 8 : 6) * uiScale),
                      decoration: BoxDecoration(
                        color: colors.surfaceAlt.withOpacity(0.6),
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
            BlocBuilder<CustomerFilterOptionsBloc, CustomerFilterOptionsState>(
              builder: (context, state) {
                List<String> states = [];
                List<String> suburbs = [];
                List<String> postcodes = [];

                if (state is CustomerFiltersLoaded) {
                  states = state.states;
                  suburbs = state.suburbs;
                  postcodes = state.postcodes;

                  if (!states.contains(selectedState)) selectedState = null;
                  if (!suburbs.contains(selectedSuburb)) selectedSuburb = null;
                  if (!postcodes.contains(selectedPostcode)) {
                    selectedPostcode = null;
                  }
                }

                if (state is CustomerFiltersLoading) {
                  return Flexible(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Loading your filter options...',
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
                          const Text(
                            'This may take a few seconds.',
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
                        _buildSectionHeader('Location'),
                        SizedBox(height: sectionGap),
                        _buildDropdown(
                          'State',
                          selectedState,
                          states,
                          (val) => setState(() => selectedState = val),
                        ),
                        SizedBox(height: sectionGap),
                        _buildDropdown(
                          'Suburb',
                          selectedSuburb,
                          suburbs,
                          (val) => setState(() => selectedSuburb = val),
                        ),
                        SizedBox(height: sectionGap),
                        _buildDropdown(
                          'Postcode',
                          selectedPostcode,
                          postcodes,
                          (val) => setState(() => selectedPostcode = val),
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
                            selectedState = null;
                            selectedSuburb = null;
                            selectedPostcode = null;
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
                          'Reset',
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
                            state: selectedState,
                            suburb: selectedSuburb,
                            postcode: selectedPostcode,
                          );

                          context.read<CustomerListBloc>().add(
                            FetchFirstCustomerPageEvent(
                              query: '',
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
                          'Apply Filters',
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

  Widget _buildSectionHeader(String title) {
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
  ) {
    final colors = context.appColors;
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
                    style: TextStyle(fontSize: 14, color: colors.onSurface),
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
