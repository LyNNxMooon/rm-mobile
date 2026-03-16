import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rmstock_scanner/constants/colors.dart';
import 'package:rmstock_scanner/entities/vos/pricing_rules.dart';
import 'package:rmstock_scanner/utils/dialog_size_utils.dart';

class PricingDialog extends StatelessWidget {
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
  final VoidCallback onUpdate;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final bool isTablet = MediaQuery.of(context).size.shortestSide >= 600;
    final double rowHeight = isTablet ? 44 : 40;
    final double columnGap = isTablet ? 18 : 12;
    final double headerSize = isTablet ? 14 : 13;
    final double textSize = isTablet ? 13 : 12;
    final double priceSize = isTablet ? 13 : 12;

    final rows = _buildRows();
    final bool showEmpty = pricingRules.isEmpty;

    return Dialog(
      insetPadding: dialogInsetPadding(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Pricing Grades",
              style: TextStyle(
                fontSize: isTablet ? 18 : 16,
                fontWeight: FontWeight.w700,
                color: kPrimaryColor,
              ),
            ),
            const SizedBox(height: 12),
            if (showEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  "No pricing grade applied for this stock item.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: textSize,
                    color: kThirdColor.withOpacity(0.75),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Grade | Rule",
                          style: TextStyle(
                            fontSize: headerSize,
                            fontWeight: FontWeight.w700,
                            color: kThirdColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...rows.map(
                          (row) => SizedBox(
                            height: rowHeight,
                            child: Row(
                              children: [
                                Radio<String>(
                                  value: row.grade,
                                  groupValue: 'Def',
                                  onChanged: null,
                                  activeColor: kPrimaryColor,
                                ),
                                SizedBox(
                                  width: isTablet ? 32 : 26,
                                  child: Text(
                                    row.grade,
                                    style: TextStyle(
                                      fontSize: textSize,
                                      fontWeight: FontWeight.w700,
                                      color: kThirdColor,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: kSecondaryColor.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: kSecondaryColor.withOpacity(0.3),
                                      ),
                                    ),
                                    child: Text(
                                      row.ruleLabel,
                                      style: TextStyle(
                                        fontSize: textSize,
                                        fontWeight: FontWeight.w600,
                                        color: kThirdColor,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: columnGap),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Stock",
                          style: TextStyle(
                            fontSize: headerSize,
                            fontWeight: FontWeight.w700,
                            color: kThirdColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...rows.map(
                          (row) => SizedBox(
                            height: rowHeight,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                _formatMoney(row.calculatedPrice),
                                style: TextStyle(
                                  fontSize: priceSize,
                                  fontWeight: FontWeight.w700,
                                  color: kPrimaryColor,
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
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onDelete,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: kPrimaryColor.withOpacity(0.7)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      "Delete",
                      style: TextStyle(
                        color: kPrimaryColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onUpdate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      "Add/Update",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              "This is the pricing grades at Stock Level Only! If you need to view other Depts/Cats & Global level pricing rules, please refer to your RetailManager System.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isTablet ? 11 : 10,
                color: kThirdColor.withOpacity(0.65),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<_PricingRow> _buildRows() {
    return [
      _PricingRow(
        grade: 'Def',
        ruleType: pricingRules.defaultRule,
        ruleValue: pricingRules.defaultValue,
        calculatedPrice: _calculatePrice(
          pricingRules.defaultRule,
          pricingRules.defaultValue,
        ),
      ),
      _PricingRow(
        grade: 'A',
        ruleType: pricingRules.ruleA,
        ruleValue: pricingRules.valueA,
        calculatedPrice: _calculatePrice(
          pricingRules.ruleA,
          pricingRules.valueA,
        ),
      ),
      _PricingRow(
        grade: 'B',
        ruleType: pricingRules.ruleB,
        ruleValue: pricingRules.valueB,
        calculatedPrice: _calculatePrice(
          pricingRules.ruleB,
          pricingRules.valueB,
        ),
      ),
      _PricingRow(
        grade: 'C',
        ruleType: pricingRules.ruleC,
        ruleValue: pricingRules.valueC,
        calculatedPrice: _calculatePrice(
          pricingRules.ruleC,
          pricingRules.valueC,
        ),
      ),
      _PricingRow(
        grade: 'D',
        ruleType: pricingRules.ruleD,
        ruleValue: pricingRules.valueD,
        calculatedPrice: _calculatePrice(
          pricingRules.ruleD,
          pricingRules.valueD,
        ),
      ),
    ];
  }

  double _calculatePrice(int ruleType, double value) {
    switch (ruleType) {
      case 1:
        return sell - (sell * (value / 100));
      case 2:
        return sell - value;
      case 3:
        return value;
      case 4:
        return cost + (cost * (value / 100));
      case 5:
        return cost + value;
      default:
        return sell;
    }
  }

  String _formatMoney(double value) {
    final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    return formatter.format(value);
  }
}

class _PricingRow {
  _PricingRow({
    required this.grade,
    required this.ruleType,
    required this.ruleValue,
    required this.calculatedPrice,
  });

  final String grade;
  final int ruleType;
  final double ruleValue;
  final double calculatedPrice;

  String get ruleLabel {
    final label = _ruleTypeLabel(ruleType);
    if (ruleType == 1 || ruleType == 4) {
      return "$label ${ruleValue.toStringAsFixed(2)}%";
    }
    if (ruleType == 2 || ruleType == 3 || ruleType == 5) {
      return "$label ${ruleValue.toStringAsFixed(2)}";
    }
    return label;
  }

  String _ruleTypeLabel(int ruleType) {
    switch (ruleType) {
      case 1:
        return "RRP -%";
      case 2:
        return "RRP -\$";
      case 3:
        return "Fixed \$";
      case 4:
        return "Cost +%";
      case 5:
        return "Cost +\$";
      default:
        return "<none>";
    }
  }
}
