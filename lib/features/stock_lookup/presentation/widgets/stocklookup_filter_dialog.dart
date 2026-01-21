import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rmstock_scanner/features/stock_lookup/presentation/BLoC/stock_lookup_bloc.dart';
import 'package:rmstock_scanner/features/stock_lookup/presentation/BLoC/stock_lookup_states.dart';
import 'package:rmstock_scanner/utils/navigation_extension.dart';

import '../../../../constants/colors.dart';
import '../../../../constants/global_widgets.dart';
import '../../../../constants/txt_styles.dart';
import '../../../../entities/vos/filter_criteria.dart';
import '../BLoC/stock_lookup_events.dart';

//Common Variables
final custom1Controller = TextEditingController();
final custom2Controller = TextEditingController();
final supplierController = TextEditingController();

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

      //Populate text controllers from active filters
      supplierController.text = filters.supplier ?? "";
      custom1Controller.text = filters.custom1 ?? "";
      custom2Controller.text = filters.custom2 ?? "";
      super.initState();
    }
  }

  String? selectedDept;
  String? selectedCat1;
  String? selectedCat2;
  String? selectedCat3;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 650),
        decoration: BoxDecoration(
          color: kBgColor,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: kThirdColor.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                gradient: kGColor,
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
                  Text("Filter Stock", style: getSmartTitle()),
                  InkWell(
                    onTap: () => context.navigateBack(),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: kGreyColor.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 18,
                        color: kSecondaryColor,
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
                              color: kThirdColor,
                              fontSize: 16,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                              top: 25,
                              left: 60,
                              right: 60,
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
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader("Classifications"),
                        const SizedBox(height: 12),
                        _buildDropdown(
                          "Department",
                          selectedDept,
                          depts,
                          (val) => setState(() => selectedDept = val),
                        ),
                        const SizedBox(height: 12),
                        _buildDropdown(
                          "Category 1",
                          selectedCat1,
                          c1,
                          (val) => setState(() => selectedCat1 = val),
                        ),
                        const SizedBox(height: 12),
                        _buildDropdown(
                          "Category 2",
                          selectedCat2,
                          c2,
                          (val) => setState(() => selectedCat2 = val),
                        ),
                        const SizedBox(height: 12),
                        _buildDropdown(
                          "Category 3",
                          selectedCat3,
                          c3,
                          (val) => setState(() => selectedCat3 = val),
                        ),

                        const SizedBox(height: 24),
                        _buildSectionHeader("Sourcing"),
                        const SizedBox(height: 12),
                        CustomTextField(
                          controller: supplierController,
                          hintText: 'Supplier',
                        ),

                        const SizedBox(height: 24),
                        _buildSectionHeader("Custom Data"),
                        const SizedBox(height: 12),
                        CustomTextField(
                          controller: custom1Controller,
                          hintText: 'Custom1',
                        ),
                        const SizedBox(height: 12),
                        CustomTextField(
                          controller: custom2Controller,
                          hintText: 'Custom2',
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          selectedDept = null;
                          selectedCat1 = null;
                          selectedCat2 = null;
                          selectedCat3 = null;
                        });
                        supplierController.clear();
                        custom1Controller.clear();
                        custom2Controller.clear();
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: kGreyColor.withOpacity(0.3)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        "Reset",
                        style: TextStyle(color: kThirdColor.withOpacity(0.6)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final criteria = FilterCriteria(
                          dept: selectedDept,
                          cat1: selectedCat1,
                          cat2: selectedCat2,
                          cat3: selectedCat3,
                          supplier: supplierController.text.trim(),
                          custom1: custom1Controller.text.trim(),
                          custom2: custom2Controller.text.trim(),
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
                      child: const Text(
                        "Apply Filters",
                        style: TextStyle(
                          color: kSecondaryColor,
                          fontWeight: FontWeight.bold,
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: kSecondaryColor,
        border: Border.all(color: kGreyColor.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          dropdownColor: kSecondaryColor,
          hint: Text(
            hint,
            style: const TextStyle(color: kGreyColor, fontSize: 14),
          ),
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: kGreyColor,
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
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
