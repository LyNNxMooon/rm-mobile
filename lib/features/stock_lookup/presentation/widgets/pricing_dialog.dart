import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rmstock_scanner/constants/colors.dart';
import 'package:rmstock_scanner/entities/vos/pricing_rules.dart';
import 'package:rmstock_scanner/utils/dialog_size_utils.dart';

class PricingDialog extends StatefulWidget {
  const PricingDialog({
    super.key,
    required this.pricingRules,
    required this.sell,
    required this.cost,
    required this.onUpdate,
    required this.onDelete,
  });

  final PricingRules pricingRules;
  final double sell;
  final double cost;
  final ValueChanged<PricingRules> onUpdate;
  final VoidCallback onDelete;

  @override
  State<PricingDialog> createState() => _PricingDialogState();
}

class _PricingDialogState extends State<PricingDialog> {
  late final List<_EditablePricingRow> _rows;
  String _selectedGrade = 'Def';

  @override
  void initState() {
    super.initState();
    _rows = [
      _EditablePricingRow(
        grade: 'Def',
        ruleType: widget.pricingRules.defaultRule,
        controller: TextEditingController(
          text: _formatValue(widget.pricingRules.defaultValue),
        ),
      ),
      _EditablePricingRow(
        grade: 'A',
        ruleType: widget.pricingRules.ruleA,
        controller: TextEditingController(
          text: _formatValue(widget.pricingRules.valueA),
        ),
      ),
      _EditablePricingRow(
        grade: 'B',
        ruleType: widget.pricingRules.ruleB,
        controller: TextEditingController(
          text: _formatValue(widget.pricingRules.valueB),
        ),
      ),
      _EditablePricingRow(
        grade: 'C',
        ruleType: widget.pricingRules.ruleC,
        controller: TextEditingController(
          text: _formatValue(widget.pricingRules.valueC),
        ),
      ),
      _EditablePricingRow(
        grade: 'D',
        ruleType: widget.pricingRules.ruleD,
        controller: TextEditingController(
          text: _formatValue(widget.pricingRules.valueD),
        ),
      ),
    ];
  }

  @override
  void dispose() {
    for (final row in _rows) {
      row.controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isTablet = MediaQuery.of(context).size.shortestSide >= 600;
    
    // ENLARGED: Font sizes increased for better readability
    final double headerSize = isTablet ? 16 : 14;
    final double textSize = isTablet ? 15 : 13;
    final double priceSize = isTablet ? 15 : 14;
    
    // ENLARGED: Wider columns to prevent squishing
    final double gradeColWidth = isTablet ? 90.0 : 75.0;
    final double amountColWidth = isTablet ? 110.0 : 85.0;
    
    // ENLARGED: Taller inputs and more space between rows
    final double inputHeight = isTablet ? 42.0 : 36.0;
    final double rowSpacing = isTablet ? 18.0 : 14.0;

    final bool hasPricingApplied = _hasPricingApplied();

    return Dialog(
      insetPadding: dialogInsetPadding(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      child: Container(
        // ENLARGED: Increased max width and added max height
        constraints: BoxConstraints(
          maxWidth: isTablet ? 760 : 600,
          maxHeight: isTablet ? 720 : 600,
        ),
        // ENLARGED: More outer padding
        padding: EdgeInsets.fromLTRB(28, 28, 28, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Pricing Grades",
              style: TextStyle(
                fontSize: isTablet ? 22 : 18,
                fontWeight: FontWeight.w700,
                color: kPrimaryColor,
              ),
            ),
            SizedBox(height: isTablet ? 24 : 16),
            Flexible(
              child: SingleChildScrollView(
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left Column (Grade, Rule, Amount)
                      Expanded(
                        flex: 7, // Gave the left side slightly more room relative to the right
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                SizedBox(
                                  width: gradeColWidth,
                                  child: Text(
                                    "Grade",
                                    style: TextStyle(
                                      fontSize: headerSize,
                                      color: kThirdColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    "Rule",
                                    style: TextStyle(
                                      fontSize: headerSize,
                                      color: kThirdColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: amountColWidth,
                                  child: Text(
                                    "Amount",
                                    style: TextStyle(
                                      fontSize: headerSize,
                                      color: kThirdColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: isTablet ? 16 : 12),
                            ..._rows.map((row) => _buildInputRow(
                                row, 
                                textSize, 
                                inputHeight, 
                                gradeColWidth, 
                                amountColWidth, 
                                rowSpacing
                            )),
                          ],
                        ),
                      ),
                      
                      // Vertical Divider
                      Container(
                        width: 1,
                        color: Colors.grey.shade300,
                        margin: EdgeInsets.symmetric(horizontal: isTablet ? 24 : 16),
                      ),
        
                      // Right Column (Calculated Stock Prices)
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Stock",
                              style: TextStyle(
                                fontSize: headerSize,
                                color: kThirdColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: isTablet ? 16 : 12),
                            if (!hasPricingApplied)
                              Expanded(
                                child: Center(
                                  child: Text(
                                    "No pricing grade applied.",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: textSize,
                                      color: kThirdColor.withOpacity(0.75),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              )
                            else
                              ..._rows.map((row) => Container(
                                    height: inputHeight,
                                    margin: EdgeInsets.only(bottom: rowSpacing),
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      _formatMoney(
                                        _calculatePrice(
                                          row.ruleType,
                                          _parseValue(row.controller.text),
                                        ),
                                      ),
                                      style: TextStyle(
                                        fontSize: priceSize,
                                        fontWeight: FontWeight.w700,
                                        color: kPrimaryColor,
                                      ),
                                    ),
                                  )),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: isTablet ? 28 : 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.onDelete,
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: isTablet ? 18 : 14),
                      side: BorderSide(color: kPrimaryColor.withOpacity(0.7)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      "Delete",
                      style: TextStyle(
                        fontSize: isTablet ? 16 : 14,
                        color: kPrimaryColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _handleUpdate,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: isTablet ? 18 : 14),
                      backgroundColor: kPrimaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      "Add/Update",
                      style: TextStyle(
                        fontSize: isTablet ? 16 : 14,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              "This is the pricing grades at Stock Level Only! If you need to view other Depts/Cats & Global level pricing rules, please refer to your RetailManager System.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isTablet ? 12 : 10,
                color: kThirdColor.withOpacity(0.65),
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputRow(
      _EditablePricingRow row, 
      double textSize, 
      double inputHeight,
      double gradeColWidth,
      double amountColWidth,
      double rowSpacing) {
    return Container(
      margin: EdgeInsets.only(bottom: rowSpacing),
      height: inputHeight, 
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Radio Button + Label
          SizedBox(
            width: gradeColWidth,
            child: Row(
              children: [
                SizedBox(
                  width: 24,
                  child: Radio<String>(
                    value: row.grade,
                    groupValue: _selectedGrade,
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedGrade = val);
                    },
                    activeColor: kPrimaryColor,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: const VisualDensity(
                      horizontal: VisualDensity.minimumDensity,
                      vertical: VisualDensity.minimumDensity,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  row.grade,
                  style: TextStyle(
                    fontSize: textSize,
                    fontWeight: FontWeight.w600,
                    color: kThirdColor,
                  ),
                ),
              ],
            ),
          ),
          
          // Dropdown for Rule
          Expanded(
            child: Container(
              height: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(6),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: row.ruleType,
                  isExpanded: true,
                  icon: const Icon(Icons.arrow_drop_down, size: 24),
                  style: TextStyle(
                    fontSize: textSize,
                    fontWeight: FontWeight.w500,
                    color: kThirdColor,
                  ),
                  items: _ruleOptions
                      .map((opt) => DropdownMenuItem<int>(
                            value: opt.value,
                            child: Text(opt.label),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        row.ruleType = value;
                      });
                    }
                  },
                ),
              ),
            ),
          ),

          // TextField for Amount
          SizedBox(
            width: amountColWidth,
            height: double.infinity,
            child: TextField(
              controller: row.controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(
                fontSize: textSize,
                color: kThirdColor,
                fontWeight: FontWeight.w500,
              ),
              textAlignVertical: TextAlignVertical.center,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: kPrimaryColor, width: 1),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Logic methods remain exactly the same
  void _handleUpdate() {
    widget.onUpdate(
      PricingRules(
        defaultRule: _rowByGrade('Def').ruleType,
        ruleA: _rowByGrade('A').ruleType,
        ruleB: _rowByGrade('B').ruleType,
        ruleC: _rowByGrade('C').ruleType,
        ruleD: _rowByGrade('D').ruleType,
        defaultValue: _parseValue(_rowByGrade('Def').controller.text),
        valueA: _parseValue(_rowByGrade('A').controller.text),
        valueB: _parseValue(_rowByGrade('B').controller.text),
        valueC: _parseValue(_rowByGrade('C').controller.text),
        valueD: _parseValue(_rowByGrade('D').controller.text),
        dateModified: DateTime.now().toIso8601String(),
      ),
    );
  }

  _EditablePricingRow _rowByGrade(String grade) {
    return _rows.firstWhere((row) => row.grade == grade);
  }

  bool _hasPricingApplied() {
    for (final row in _rows) {
      final value = _parseValue(row.controller.text);
      if (row.ruleType != 0 || value != 0) {
        return true;
      }
    }
    return false;
  }

  double _calculatePrice(int ruleType, double value) {
    switch (ruleType) {
      case 1:
        return widget.sell - (widget.sell * (value / 100));
      case 2:
        return widget.sell - value;
      case 3:
        return value;
      case 4:
        return widget.cost + (widget.cost * (value / 100));
      case 5:
        return widget.cost + value;
      default:
        return widget.sell;
    }
  }

  String _formatMoney(double value) {
    final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    return formatter.format(value);
  }

  double _parseValue(String text) {
    final raw = text.trim();
    if (raw.isEmpty) return 0;
    return double.tryParse(raw) ?? 0;
  }

  String _formatValue(double value) {
    if (value == 0) return "";
    return value.toStringAsFixed(2);
  }
}

class _EditablePricingRow {
  _EditablePricingRow({
    required this.grade,
    required this.ruleType,
    required this.controller,
  });

  final String grade;
  int ruleType;
  final TextEditingController controller;
}

class _RuleOption {
  const _RuleOption(this.value, this.label);

  final int value;
  final String label;
}

const List<_RuleOption> _ruleOptions = [
  _RuleOption(0, "<none>"),
  _RuleOption(1, "RRP -%"),
  _RuleOption(2, "RRP -\$"),
  _RuleOption(3, "Fixed \$"),
  _RuleOption(4, "Cost +%"),
  _RuleOption(5, "Cost +\$"),
];