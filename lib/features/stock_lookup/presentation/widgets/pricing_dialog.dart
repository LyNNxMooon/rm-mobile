import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rmmobile/constants/colors.dart';
import 'package:rmmobile/constants/theme_colors.dart';
import 'package:rmmobile/entities/vos/pricing_grades.dart';
import 'package:rmmobile/entities/vos/pricing_rules.dart';
import 'package:rmmobile/utils/dialog_size_utils.dart';
import 'package:rmmobile/utils/responsive_utils.dart';

class PricingDialog extends StatefulWidget {
  const PricingDialog({
    super.key,
    required this.pricingRules,
    required this.sell,
    required this.cost,
    required this.onUpdate,
    required this.onDelete,
    this.pricingGradesStock,
    this.pricingGradesCategories,
    this.pricingGradesGlobal,
  });

  final PricingRules pricingRules;
  final double sell;
  final double cost;
  final ValueChanged<PricingRules> onUpdate;
  final VoidCallback onDelete;
  final PricingGrades? pricingGradesStock;
  final PricingGrades? pricingGradesCategories;
  final PricingGrades? pricingGradesGlobal;

  @override
  State<PricingDialog> createState() => _PricingDialogState();
}

/// Pricing level for display: Stock, Depts&Cats, Global
enum _PricingLevel { stock, categories, global }

class _PricingDialogState extends State<PricingDialog> {
  late final List<_EditablePricingRow> _rows;
  String _selectedGrade = 'Def';
  _PricingLevel _currentLevel = _PricingLevel.stock;

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
    final colors = context.appColors;
    final bool isDark = colors.isDark;
    final Color textColor = isDark ? colors.onSurface : kThirdColor;
    final Color mutedText =
            isDark ? colors.onSurfaceMuted : kThirdColor.withOpacity(0.75);
    final Color surface = isDark ? colors.surfaceAlt : Colors.white;
    //final Color surfaceAlt = isDark ? colors.surfaceAlt : Colors.grey.shade50;
    final Color divider = isDark ? colors.divider : Colors.grey.shade300;
    final bool isTablet = context.isTablet;
    
    final double headerSize = isTablet ? 16 : 13;
    final double textSize = isTablet ? 15 : 13;
    final double priceSize = isTablet ? 15 : 13;
    
    // ALIGNMENT FIX: Adjusted widths so "Amount" has room to breathe and "Grade" lines up
    final double gradeColWidth = isTablet ? 90.0 : 75.0; 
    final double amountColWidth = isTablet ? 110.0 : 80.0; 
    final double middleGap = isTablet ? 16.0 : 8.0;
    
    final double inputHeight = isTablet ? 42.0 : 34.0;
    final double rowSpacing = isTablet ? 18.0 : 10.0;
    final double stockColWidth = isTablet ? 0.0 : 84.0;

    final EdgeInsets customInsetPadding = isTablet
        ? dialogInsetPadding(context)
        : const EdgeInsets.symmetric(horizontal: 12, vertical: 24);

    return Dialog(
      insetPadding: customInsetPadding,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isDark
            ? const BorderSide(color: Colors.white30, width: 1)
            : BorderSide.none,
      ),
      backgroundColor: surface,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isTablet ? 780 : 680, 
          maxHeight: isTablet ? 720 : 600,
        ),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(
            isTablet ? 24 : 16, 
            isTablet ? 24 : 16, 
            isTablet ? 24 : 16, 
            isTablet ? 20 : 16
          ),
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
                  child: isTablet
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Left Column (Grade, Rule, Amount)
                            Expanded(
                              flex: 7, 
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // PERFECT ALIGNMENT HEADERS
                                  Row(
                                    children: [
                                      SizedBox(
                                        width: gradeColWidth,
                                        child: Padding(
                                          padding: const EdgeInsets.only(left: 4.0), // Aligns text with the visual center of the Radio button
                                          child: Text(
                                            "Grade",
                                            style: TextStyle(
                                              fontSize: headerSize,
                                              color: textColor,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Container(
                                          margin: EdgeInsets.only(right: middleGap),
                                          padding: EdgeInsets.only(left: isTablet ? 12 : 8), // Mirrors the dropdown's internal padding
                                          child: Text(
                                            "Rule",
                                            style: TextStyle(
                                              fontSize: headerSize,
                                              color: textColor,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: amountColWidth,
                                        child: Padding(
                                          padding: EdgeInsets.only(left: isTablet ? 12 : 8), // Mirrors the TextField's internal padding
                                          child: Text(
                                            "Amount",
                                            style: TextStyle(
                                              fontSize: headerSize,
                                              color: textColor,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: isTablet ? 16 : 10),
                                  ..._rows.map((row) => _buildInputRow(
                                      row, 
                                      textSize, 
                                      inputHeight, 
                                      gradeColWidth, 
                                      amountColWidth, 
                                      middleGap,
                                      rowSpacing,
                                      isTablet
                                  )),
                                ],
                              ),
                            ),
                            
                            // Vertical Divider
                            Container(
                              width: 1,
                              color: divider,
                              margin: EdgeInsets.symmetric(horizontal: isTablet ? 20 : 12),
                            ),
              
                            // Right Column (Calculated Stock Prices)
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLevelHeader(headerSize, textColor, isTablet),
                                  SizedBox(height: isTablet ? 16 : 10),
                                  ..._rows.map((row) => Container(
                                        height: inputHeight,
                                        margin: EdgeInsets.only(bottom: rowSpacing),
                                        alignment: Alignment.centerLeft,
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            _formatPriceForGrade(row.grade),
                                            style: TextStyle(
                                              fontSize: priceSize,
                                              fontWeight: FontWeight.w700,
                                              color: kPrimaryColor,
                                            ),
                                          ),
                                        ),
                                      )),
                                ],
                              ),
                            ),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLevelHeader(16, textColor, isTablet),
                            SizedBox(height: isTablet ? 16 : 10),
                            ..._rows.map((row) => _buildMobileInputRow(
                                  row,
                                  textSize,
                                  inputHeight,
                                  amountColWidth,
                                  stockColWidth,
                                  middleGap,
                                  rowSpacing,
                                )),
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
                const SizedBox(width: 12),
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
                        color: isDark ? colors.onHero : Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              "This is the pricing grades at Stock Level Only! If you need to view other Depts/Cats & Global level pricing rules, please refer to your RetailManager System.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isTablet ? 11 : 9.5,
                color: mutedText,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
          ],
        ),
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
      double middleGap,
      double rowSpacing,
      bool isTablet) {
    final colors = context.appColors;
    final bool isDark = colors.isDark;
    final Color textColor = isDark ? colors.onSurface : kThirdColor;
    final Color surface = isDark ? colors.surface : Colors.white;
    final Color surfaceAlt = isDark ? colors.surfaceAlt : Colors.grey.shade50;
    final Color divider = isDark ? colors.divider : Colors.grey.shade300;
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
                  width: isTablet ? 24 : 20,
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
                SizedBox(width: isTablet ? 8 : 4),
                Text(
                  row.grade,
                  style: TextStyle(
                    fontSize: textSize,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
          
          // Dropdown for Rule
          Expanded(
            child: Container(
              height: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: isTablet ? 12 : 8),
              margin: EdgeInsets.only(right: middleGap),
              decoration: BoxDecoration(
                color: surfaceAlt,
                border: Border.all(color: divider),
                borderRadius: BorderRadius.circular(6),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: row.ruleType,
                  isExpanded: true,
                  icon: Icon(Icons.arrow_drop_down, size: isTablet ? 22 : 18),
                  style: TextStyle(
                    fontSize: textSize,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                  items: _ruleOptions
                      .map((opt) => DropdownMenuItem<int>(
                            value: opt.value,
                            child: Text(
                              opt.label,
                              overflow: TextOverflow.ellipsis,
                            ),
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
              scrollPhysics: const ClampingScrollPhysics(),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(
                fontSize: textSize,
                color: textColor,
                fontWeight: FontWeight.w500,
              ),
              textAlignVertical: TextAlignVertical.center,
              decoration: InputDecoration(
                filled: true,
                fillColor: surface,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 12 : 8, 
                  vertical: 0
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: divider, width: 1),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: divider, width: 1),
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

  Widget _buildMobileInputRow(
      _EditablePricingRow row,
      double textSize,
      double inputHeight,
      double amountColWidth,
      double stockColWidth,
      double middleGap,
      double rowSpacing) {
    final colors = context.appColors;
    final bool isDark = colors.isDark;
    final Color textColor = isDark ? colors.onSurface : kThirdColor;
    final Color surface = isDark ? colors.surface : Colors.white;
    final Color surfaceAlt = isDark ? colors.surfaceAlt : Colors.grey.shade50;
    final Color divider = isDark ? colors.divider : Colors.grey.shade300;
    return Container(
      margin: EdgeInsets.only(bottom: rowSpacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 20,
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
              const SizedBox(width: 6),
              Text(
                row.grade,
                style: TextStyle(
                  fontSize: textSize,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Container(
                  height: inputHeight,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  margin: EdgeInsets.only(right: middleGap),
                  decoration: BoxDecoration(
                    color: surfaceAlt,
                    border: Border.all(color: divider),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: row.ruleType,
                      isExpanded: true,
                      icon: const Icon(Icons.arrow_drop_down, size: 18),
                      style: TextStyle(
                        fontSize: textSize,
                        fontWeight: FontWeight.w500,
                        color: textColor,
                      ),
                      items: _ruleOptions
                          .map((opt) => DropdownMenuItem<int>(
                                value: opt.value,
                                child: Text(
                                  opt.label,
                                  overflow: TextOverflow.ellipsis,
                                ),
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
              SizedBox(
                width: amountColWidth,
                height: inputHeight,
                child: TextField(
                  controller: row.controller,
                  scrollPhysics: const ClampingScrollPhysics(),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  style: TextStyle(
                    fontSize: textSize,
                    color: textColor,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlignVertical: TextAlignVertical.center,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: surface,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 0,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(
                        color: divider,
                        width: 1,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(
                        color: divider,
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide:
                          const BorderSide(color: kPrimaryColor, width: 1),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: stockColWidth,
                height: inputHeight,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _formatPriceForGrade(row.grade),
                      style: TextStyle(
                        fontSize: textSize,
                        fontWeight: FontWeight.w700,
                        color: kPrimaryColor,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

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

  /// Returns the label for the current pricing level
  String _getLevelLabel() {
    switch (_currentLevel) {
      case _PricingLevel.stock:
        return "Stock";
      case _PricingLevel.categories:
        return "Depts/Cats";
      case _PricingLevel.global:
        return "Global";
    }
  }

  /// Format the price for a given grade at the current level.
  /// 
  /// Hierarchy (from lowest to highest priority):
  /// - RRP (sell price) as base
  /// - Global overrides RRP
  /// - Depts/Cats overrides Global
  /// - Stock overrides Depts/Cats
  ///
  /// Based on the current viewing level, we show the effective price
  /// up to that level in the hierarchy.
  String _formatPriceForGrade(String grade) {
    double? effectivePrice;
    
    // Start with RRP as the base
    effectivePrice = widget.sell;
    
    // Apply hierarchy based on current viewing level
    switch (_currentLevel) {
      case _PricingLevel.global:
        // Global level: RRP -> Global
        final globalPrice = widget.pricingGradesGlobal?.priceForGrade(grade);
        if (globalPrice != null) effectivePrice = globalPrice;
        break;
        
      case _PricingLevel.categories:
        // Categories level: RRP -> Global -> Depts/Cats
        final globalPrice = widget.pricingGradesGlobal?.priceForGrade(grade);
        if (globalPrice != null) effectivePrice = globalPrice;
        final catPrice = widget.pricingGradesCategories?.priceForGrade(grade);
        if (catPrice != null) effectivePrice = catPrice;
        break;
        
      case _PricingLevel.stock:
        // Stock level: RRP -> Global -> Depts/Cats -> Stock
        final globalPrice = widget.pricingGradesGlobal?.priceForGrade(grade);
        if (globalPrice != null) effectivePrice = globalPrice;
        final catPrice = widget.pricingGradesCategories?.priceForGrade(grade);
        if (catPrice != null) effectivePrice = catPrice;
        final stockPrice = widget.pricingGradesStock?.priceForGrade(grade);
        if (stockPrice != null) effectivePrice = stockPrice;
        break;
    }
    
    return _formatMoney(effectivePrice);
  }

  /// Cycles to the next pricing level (up)
  void _cycleLevelUp() {
    setState(() {
      switch (_currentLevel) {
        case _PricingLevel.stock:
          _currentLevel = _PricingLevel.categories;
          break;
        case _PricingLevel.categories:
          _currentLevel = _PricingLevel.global;
          break;
        case _PricingLevel.global:
          _currentLevel = _PricingLevel.stock;
          break;
      }
    });
  }

  /// Cycles to the previous pricing level (down)
  void _cycleLevelDown() {
    setState(() {
      switch (_currentLevel) {
        case _PricingLevel.stock:
          _currentLevel = _PricingLevel.global;
          break;
        case _PricingLevel.categories:
          _currentLevel = _PricingLevel.stock;
          break;
        case _PricingLevel.global:
          _currentLevel = _PricingLevel.categories;
          break;
      }
    });
  }

  /// Builds the level header with up/down navigation arrows
  Widget _buildLevelHeader(double fontSize, Color textColor, bool isTablet) {
    final colors = context.appColors;
    final bool isDark = colors.isDark;
    final double iconSize = isTablet ? 14.0 : 12.0;
    final double buttonHeight = isTablet ? 20.0 : 16.0;
    final double buttonWidth = isTablet ? 22.0 : 18.0;
    final Color buttonBg = isDark 
        ? colors.surface 
        : Colors.grey.shade100;
    final Color buttonBorder = isDark 
        ? colors.divider 
        : Colors.grey.shade300;
    final Color iconColor = isDark 
        ? colors.onSurfaceMuted 
        : Colors.grey.shade600;
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Flexible(
          child: Text(
            _getLevelLabel(),
            style: TextStyle(
              fontSize: fontSize,
              color: textColor,
              fontWeight: FontWeight.w700,
              height: 1.0,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        SizedBox(width: isTablet ? 8 : 6),
        Container(
          decoration: BoxDecoration(
            color: buttonBg,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: buttonBorder, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: _cycleLevelUp,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(5),
                  bottomLeft: Radius.circular(5),
                ),
                child: Container(
                  width: buttonWidth,
                  height: buttonHeight,
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.keyboard_arrow_up,
                    size: iconSize,
                    color: iconColor,
                  ),
                ),
              ),
              Container(
                width: 1,
                height: buttonHeight * 0.7,
                color: buttonBorder,
              ),
              InkWell(
                onTap: _cycleLevelDown,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(5),
                  bottomRight: Radius.circular(5),
                ),
                child: Container(
                  width: buttonWidth,
                  height: buttonHeight,
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.keyboard_arrow_down,
                    size: iconSize,
                    color: iconColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
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