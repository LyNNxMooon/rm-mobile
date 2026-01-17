import 'package:flutter/material.dart';
import 'package:rmstock_scanner/utils/navigation_extension.dart';

import '../../../../constants/colors.dart';
import '../../../../constants/global_widgets.dart';
import '../../../../constants/txt_styles.dart';

//Common Variables
final sCustom1Controller = TextEditingController();
final sCustom2Controller = TextEditingController();

class FilterDialog extends StatefulWidget {
  const FilterDialog({super.key});

  @override
  State<FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends State<FilterDialog> {
  String? selectedDept;
  String? selectedCat1;
  String? selectedCat2;
  String? selectedCat3;
  String? selectedSupplier;

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

            Expanded(
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
                      (val) => setState(() => selectedDept = val),
                    ),
                    const SizedBox(height: 12),
                    _buildDropdown(
                      "Category 1",
                      selectedCat1,
                      (val) => setState(() => selectedCat1 = val),
                    ),
                    const SizedBox(height: 12),
                    _buildDropdown(
                      "Category 2",
                      selectedCat2,
                      (val) => setState(() => selectedCat2 = val),
                    ),
                    const SizedBox(height: 12),
                    _buildDropdown(
                      "Category 3",
                      selectedCat3,
                      (val) => setState(() => selectedCat3 = val),
                    ),

                    const SizedBox(height: 24),
                    _buildSectionHeader("Sourcing"),
                    const SizedBox(height: 12),
                    _buildDropdown(
                      "Supplier",
                      selectedSupplier,
                      (val) => setState(() => selectedSupplier = val),
                    ),

                    const SizedBox(height: 24),
                    _buildSectionHeader("Custom Data"),
                    const SizedBox(height: 12),
                    CustomTextField(
                      controller: sCustom1Controller,
                      hintText: 'Custom1',
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      controller: sCustom2Controller,
                      hintText: 'Custom2',
                    ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {},
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
                      onPressed: () {},
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

          items: [
            "Option A",
            "Option B",
            "Option C",
          ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        ),
      ),
    );
  }
}
