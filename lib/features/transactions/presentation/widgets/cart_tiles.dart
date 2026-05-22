import 'package:cached_network_image/cached_network_image.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/cupertino.dart' show CupertinoPicker;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rational/rational.dart';
import 'package:rmmobile/utils/tax_calculation_utils.dart';

import '../../../../constants/colors.dart';
import '../../../../constants/images.dart';
import '../../../../constants/theme_colors.dart';
import '../../../../entities/vos/cart_item_vo.dart';
import '../../../../entities/vos/serial_number_vo.dart';
import '../../../../utils/formatting_utils.dart';
import '../../../../utils/responsive_utils.dart';
import '../../../../constants/standard_dialog.dart';
import 'serial_number_dialog.dart';
import 'breakdown_widgets.dart';
import '../../../stock_lookup/presentation/widgets/price_calculator_dialog.dart';

/// Helper to format sell price - shows 4 decimals if the price has significant 
/// digits beyond 2 decimal places, otherwise shows 2 decimals (with cascade rounding)
String formatSellPriceForDisplay(double price) {
  final fixed4 = price.toStringAsFixed(4);
  final fixed2 = price.toStringAsFixed(2);
  if (double.parse(fixed4) != double.parse(fixed2)) {
    return fixed4;
  }
  return fixed2;
}

/// Helper to format qty for display
/// - For fractional items (allowFractions=true): always shows 3 decimal places
/// - For non-fractional items: shows whole number only
String formatQtyForDisplay(double qty, bool allowFractions) {
  if (allowFractions) {
    return qty.toStringAsFixed(3);
  }
  return qty.toInt().toString();
}

/// Wraps a cart tile with slide-to-delete functionality
class DismissibleCartTile extends StatelessWidget {
  final Widget child;
  final VoidCallback onDelete;
  final bool isDark;
  final AppThemeColors colors;

  const DismissibleCartTile({
    super.key,
    required this.child,
    required this.onDelete,
    required this.isDark,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: UniqueKey(),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: kErrorColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 24),
      ),
      child: child,
    );
  }
}

/// Expanded edit cart tile - shows when item is being edited
class ExpandedEditCartTile extends StatefulWidget {
  final CartItemVO item;
  final int index;
  final AppThemeColors colors;
  final bool isDark;
  final bool isTablet;
  final Function(double qty) onQtyChanged;
  final Function(double price) onPriceChanged;
  final Function(List<SerialNumberVO> serials) onSerialChanged;
  final Function(String description)? onDescriptionChanged;
  final VoidCallback onSave;
  final VoidCallback onDelete;
  final bool isIncTax;
  final double taxRate;
  final bool allowPriceEdit;
  final bool hideSerialButton;

  const ExpandedEditCartTile({
    super.key,
    required this.item,
    required this.index,
    required this.colors,
    required this.isDark,
    required this.isTablet,
    required this.onQtyChanged,
    required this.onPriceChanged,
    required this.onSerialChanged,
    this.onDescriptionChanged,
    required this.onSave,
    required this.onDelete,
    this.isIncTax = true,
    this.taxRate = 0.1,
    this.allowPriceEdit = true,
    this.hideSerialButton = false,
  });

  @override
  State<ExpandedEditCartTile> createState() => _ExpandedEditCartTileState();
}

class _ExpandedEditCartTileState extends State<ExpandedEditCartTile> {
  late TextEditingController _qtyController;
  late TextEditingController _priceController;
  late TextEditingController _descriptionController;

  // Focus nodes to track active editing (prevents cursor jumping)
  final FocusNode _qtyFocusNode = FocusNode();
  final FocusNode _priceFocusNode = FocusNode();
  final FocusNode _descriptionFocusNode = FocusNode();

  bool get _allowRenaming => widget.item.stock?.allowRenaming ?? false;
  bool get _allowFractions => widget.item.stock?.allowFractions ?? false;

  /// Format qty for display - always 3 decimals for fractional items, integer for others
  String _formatQty(double qty) {
    if (_allowFractions) {
      return qty.toStringAsFixed(3);
    }
    return qty.toInt().toString();
  }

  String _formatSellPrice(double price) {
    // Use cascade rounding for 4 and 2 decimals
    final fixed4 = price.toStringAsFixed(4);
    final fixed2 = price.toStringAsFixed(2);
    // Show 4 decimals if it has significant digits beyond 2 decimals
    if (double.parse(fixed4) != double.parse(fixed2)) {
      return fixed4;
    }
    return fixed2;
  }

  @override
  void initState() {
    super.initState();
    _qtyController = TextEditingController(text: _formatQty(widget.item.qty));
    _priceController = TextEditingController(
      text: _formatSellPrice(_displayPrice),
    );
    _descriptionController = TextEditingController(
      text: widget.item.description,
    );
  }

  @override
  void didUpdateWidget(ExpandedEditCartTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only update controller text if the field doesn't have focus (user not actively editing)
    if (oldWidget.item.qty != widget.item.qty && !_qtyFocusNode.hasFocus) {
      _qtyController.text = _formatQty(widget.item.qty);
    }
    // Update price when incPrice/exPrice changes or tax toggle changes
    final oldDisplayPrice = oldWidget.isIncTax
        ? oldWidget.item.incPrice
        : oldWidget.item.exPrice;
    if ((oldDisplayPrice != _displayPrice || oldWidget.isIncTax != widget.isIncTax) && !_priceFocusNode.hasFocus) {
      _priceController.text = _formatSellPrice(_displayPrice);
    }
    if (oldWidget.item.description != widget.item.description && !_descriptionFocusNode.hasFocus) {
      _descriptionController.text = widget.item.description;
    }
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _priceController.dispose();
    _qtyFocusNode.dispose();
    _priceFocusNode.dispose();
    _descriptionFocusNode.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  double get _displayPrice => widget.isIncTax
      ? widget.item.incPrice
      : widget.item.exPrice;

  double get _displayExtension => widget.isIncTax
      ? widget.item.extension
      : widget.item.extensionEx;

  void _incrementQty() {
    final current = double.tryParse(_qtyController.text) ?? 1.0;
    final newQty = current + 1;
    _qtyController.text = _formatQty(newQty);
    widget.onQtyChanged(newQty);
  }

  void _decrementQty() {
    final current = double.tryParse(_qtyController.text) ?? 1.0;
    final newQty = current - 1;
    _qtyController.text = _formatQty(newQty);
    widget.onQtyChanged(newQty);
  }

  bool get _hasPromotion {
    final stock = widget.item.stock;
    return stock?.isOnPromotion == true &&
        stock?.promotion?.promotionRrp != null;
  }

  Future<void> _showPricingGradeDialog() async {
    if (_hasPromotion) {
      return;
    }
    final stock = widget.item.stock;
    if (stock == null) {
      return;
    }

    final List<String> grades = const ['Def', 'A', 'B', 'C', 'D'];
    int selectedIndex = 0;
    final TextEditingController priceController = TextEditingController();

    Future<void> updatePriceForGrade(int gradeIndex) async {
      final gradeInt = gradeIndex.clamp(0, grades.length - 1);
      final result = stock.getEffectiveSellPrice(gradeInt);
      final double effectiveSell = result.price;

      double incPrice;
      double exPrice;

      if (result.isPricingGradeApplied) {
        // Pricing grade prices are already inc-tax
        final taxResult = await TaxCalculationUtils.calculateSellTax(
          sell: stock.sell,
          salesTax: stock.salesTax,
        );
        final double taxPercentage = taxResult.percentage;
        incPrice = effectiveSell;
        final multiplier = 1 + (taxPercentage / 100);
        exPrice = taxPercentage > 0 ? effectiveSell / multiplier : effectiveSell;
      } else if (stock.isPackage && stock.sellEx != null && stock.sellInc != null) {
        // Package items with no pricing grade: use sell_ex/sell_inc directly
        incPrice = stock.sellInc!;
        exPrice = stock.sellEx!;
      } else {
        final taxResult = await TaxCalculationUtils.calculateSellTax(
          sell: effectiveSell,
          salesTax: stock.salesTax,
        );
        incPrice = taxResult.incPrice;
        exPrice = taxResult.exPrice;
      }

      final displayPrice = widget.isIncTax ? incPrice : exPrice;
      priceController.text = _formatSellPrice(displayPrice);
    }

    // Initialize with Def price from stock pricing hierarchy
    await updatePriceForGrade(selectedIndex);

    await showDialog(
      context: context,
      builder: (context) {
        final colors = widget.colors;
        final bool isDark = widget.isDark;
        final bool isTablet = widget.isTablet;

        return StatefulBuilder(
          builder: (context, setState) {
            return StandardDialog(
              title: "Pricing Grade",
              colors: colors,
              isDark: isDark,
              maxWidth: isTablet ? 420 : 320,
              onClose: () => Navigator.of(context).pop(),
              content: SizedBox(
                width: isTablet ? 420 : 320,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Price",
                            style: TextStyle(
                              fontSize: isTablet ? 14 : 12,
                              color: isDark
                                  ? colors.onSurfaceMuted
                                  : Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 6),
                          SizedBox(
                            height: isTablet ? 48 : 38,
                            child: TextField(
                              controller: priceController,
                              scrollPhysics: const ClampingScrollPhysics(),
                              keyboardType: const TextInputType.numberWithOptions(
                                signed: true,
                                decimal: true,
                              ),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'^-?\d*\.?\d{0,4}'),
                                ),
                              ],
                              style: TextStyle(
                                fontSize: isTablet ? 18 : 14,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                              decoration: InputDecoration(
                                prefixText: "\$",
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: isTablet ? 12 : 10,
                                  vertical: isTablet ? 12 : 10,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: isDark
                                        ? Colors.white24
                                        : Colors.grey.shade300,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: isDark
                                        ? Colors.white24
                                        : Colors.grey.shade300,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                    color: kPrimaryColor,
                                  ),
                                ),
                                filled: true,
                                fillColor: isDark
                                    ? colors.surfaceAlt
                                    : Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: isTablet ? 16 : 12),
                    SizedBox(
                      width: isTablet ? 90 : 70,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Grade",
                            style: TextStyle(
                              fontSize: isTablet ? 14 : 12,
                              color: isDark
                                  ? colors.onSurfaceMuted
                                  : Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 6),
                          SizedBox(
                            height: isTablet ? 120 : 100,
                            child: CupertinoPicker(
                              itemExtent: isTablet ? 36 : 30,
                              scrollController: FixedExtentScrollController(
                                initialItem: selectedIndex,
                              ),
                              onSelectedItemChanged: (index) {
                                setState(() {
                                  selectedIndex = index;
                                });
                                updatePriceForGrade(index);
                              },
                              children: [
                                for (final grade in grades)
                                  Center(
                                    child: Text(
                                      grade,
                                      style: TextStyle(
                                        fontSize: isTablet ? 18 : 14,
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black87,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                DialogTextAction(
                  label: "Cancel",
                  style: DialogActionStyle.cancelOutline,
                  onPressed: () => Navigator.of(context).pop(),
                ),
                DialogTextAction(
                  label: "Save",
                  style: DialogActionStyle.primary,
                  onPressed: () {
                    final parsed = double.tryParse(priceController.text.trim());
                    if (parsed != null) {
                      _priceController.text = _formatSellPrice(parsed);
                      widget.onPriceChanged(parsed);
                      widget.onSave();
                    }
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = widget.isTablet;
    final bool useDesktopNav = context.useDesktopNav;
    final bool hasPromotion = _hasPromotion;
    
    // Desktop-specific sizes (between mobile and tablet)
    final double containerPadding = useDesktopNav ? 10 : (isTablet ? 12 : 10);
    final double thumbnailSize = useDesktopNav ? 36 : (isTablet ? 44 : 36);
    final double descFontSize = useDesktopNav ? 13 : 14;
    final double codeFontSize = useDesktopNav ? 12 : 13;
    final double totalLabelFontSize = useDesktopNav ? 9 : (isTablet ? 10 : 9);
    final double totalFontSize = useDesktopNav ? 13 : (isTablet ? 15 : 13);
    final double fieldHeight = useDesktopNav ? 40 : (isTablet ? 52 : 30);
    final double priceFieldWidth = useDesktopNav ? 100 : (isTablet ? 220 : 100);
    final double qtyFieldWidth = useDesktopNav ? 70 : (isTablet ? 100 : 50);

    return Container(
      padding: EdgeInsets.all(containerPadding),
      decoration: BoxDecoration(
        color: widget.isDark
            ? Color.lerp(widget.colors.surface, kPrimaryColor, 0.08)
            : kPrimaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kPrimaryColor.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header row: Thumbnail + Description + Total
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Thumbnail
              Container(
                width: thumbnailSize,
                height: thumbnailSize,
                margin: EdgeInsets.only(right: useDesktopNav ? 6 : (isTablet ? 10 : 8)),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: widget.isDark ? widget.colors.surface : Colors.white,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: widget.item.stock?.imageUrl != null &&
                          widget.item.stock!.imageUrl!.trim().isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: widget.item.stock!.imageUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, _) =>
                              Image.asset(overviewPlaceholder, fit: BoxFit.fill),
                          errorWidget: (_, _, _) =>
                              Image.asset(overviewPlaceholder, fit: BoxFit.fill),
                        )
                      : Image.asset(overviewPlaceholder, fit: BoxFit.fill),
                ),
              ),
              // Item details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_allowRenaming)
                      _buildDescriptionField(isTablet, useDesktopNav: useDesktopNav)
                    else
                      Text(
                        widget.item.description,
                        style: TextStyle(
                          fontSize: descFontSize,
                          fontWeight: FontWeight.w600,
                          color: widget.isDark ? Colors.white : Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    Text(
                      widget.item.code,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: codeFontSize,
                        fontWeight: FontWeight.w900,
                        color: kPrimaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: useDesktopNav ? 6 : (isTablet ? 12 : 8)),
              // Total display
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Total",
                    style: TextStyle(
                      fontSize: totalLabelFontSize,
                      color: widget.colors.onSurfaceMuted,
                    ),
                  ),
                  Text(
                    FormattingUtils.formatCurrencyWithDecimals(
                      _displayExtension,
                      2,
                    ),
                    style: TextStyle(
                      fontSize: totalFontSize,
                      fontWeight: FontWeight.bold,
                      color: widget.isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
            ],
          ),

          SizedBox(height: useDesktopNav ? 6 : (isTablet ? 10 : 8)),

          // Edit fields and actions row - horizontally scrollable for narrow screens
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Flexible(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  reverse: true,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Action buttons
                      if (widget.item.trackSerial && !widget.hideSerialButton) ...[
                        _buildSerialButton(
                          onTap: () => _showSerialDialog(context),
                          isTablet: isTablet,
                          hasValue: widget.item.serialNumbers.isNotEmpty,
                          useDesktopNav: useDesktopNav,
                        ),
                        SizedBox(width: useDesktopNav ? 4 : (isTablet ? 6 : 4)),
                      ],

                      // Tax & GP button (combined)
                      _buildTaxGpButton(
                        onTap: () => _showItemTaxAndGpDialog(context),
                        isTablet: isTablet,
                        useDesktopNav: useDesktopNav,
                      ),
                      SizedBox(width: useDesktopNav ? 20 : (isTablet ? 6 : 4)),

                      // Sell Price field
                      Padding(
                        padding: EdgeInsets.only(top: useDesktopNav ? 7 : 0),
                        child: SizedBox(
                          width: priceFieldWidth,
                          height: fieldHeight,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Positioned.fill(
                                child: _buildCompactField(
                                  label: "Price",
                                  controller: _priceController,
                                  prefix: "\$",
                                  isTablet: isTablet,
                                  maxDecimals: 4,
                                  enabled: widget.allowPriceEdit,
                                  focusNode: _priceFocusNode,
                                  selectAllOnTap: true,
                                  useDesktopNav: useDesktopNav,
                                  onChanged: (value) {
                                    final price = double.tryParse(value);
                                    if (price != null) widget.onPriceChanged(price);
                                  },
                                ),
                              ),
                              if (hasPromotion)
                                Positioned(
                                  left: 2,
                                  top: useDesktopNav ? -10 : (isTablet ? -14 : -10),
                                  child: Text(
                                    "(*Promotion)",
                                    style: TextStyle(
                                      fontSize: useDesktopNav ? 9 : (isTablet ? 11 : 9),
                                      color: kErrorColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(width: useDesktopNav ? 20 : (isTablet ? 10 : 6)),

                      // Calculator button (mobile: replaces arrows, tablet: before arrows)
                      _buildCalculatorButton(
                        onTap: widget.allowPriceEdit ? () => _openPriceCalculator(context) : null,
                        isTablet: isTablet,
                        enabled: widget.allowPriceEdit,
                        useDesktopNav: useDesktopNav,
                      ),
                      SizedBox(width: useDesktopNav ? 20 : (isTablet ? 6 : 4)),

                      // Grade arrows - tablet and desktop in this row
                      if (isTablet || useDesktopNav) ...[                        
                        _buildGradePickerArrows(
                          isTablet: isTablet,
                          enabled: !hasPromotion,
                          useDesktopNav: useDesktopNav,
                        ),
                        SizedBox(width: useDesktopNav ? 20 : 10),
                      ],

                      // Qty with +/- buttons
                      _buildQtyButton(
                        icon: Icons.remove,
                        onTap: _decrementQty,
                        isTablet: isTablet,
                        useDesktopNav: useDesktopNav,
                      ),
                      SizedBox(width: useDesktopNav ? 4 : (isTablet ? 10 : 2)),
                      Padding(
                        padding: EdgeInsets.only(top: useDesktopNav ? 7 : 0),
                        child: SizedBox(
                          width: qtyFieldWidth,
                          height: fieldHeight,
                          child: _buildCompactField(
                            controller: _qtyController,
                            isTablet: isTablet,
                            textAlign: TextAlign.center,
                            isNumber: !_allowFractions,
                            maxDecimals: _allowFractions ? 3 : null,
                            focusNode: _qtyFocusNode,
                            useDesktopNav: useDesktopNav,
                            onChanged: (value) {
                              final qty = double.tryParse(value);
                              if (qty != null && qty != 0) widget.onQtyChanged(qty);
                            },
                          ),
                        ),
                      ),
                      SizedBox(width: useDesktopNav ? 4 : (isTablet ? 10 : 2)),
                      _buildQtyButton(
                        icon: Icons.add,
                        onTap: _incrementQty,
                        isTablet: isTablet,
                        useDesktopNav: useDesktopNav,
                      ),

                      // Delete and Save buttons - only in this row for tablet and desktop
                      if (isTablet || useDesktopNav) ...[
                        SizedBox(width: useDesktopNav ? 20 : 6),

                        _buildIconButton(
                          icon: Icons.delete_outline,
                          onTap: widget.onDelete,
                          isTablet: isTablet,
                          isDestructive: true,
                          useDesktopNav: useDesktopNav,
                        ),

                        SizedBox(width: useDesktopNav ? 20 : 6),

                        // Save button
                        _buildCompactSaveButton(isTablet: isTablet, useDesktopNav: useDesktopNav),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Grade arrows, Delete and Save buttons - separate row for mobile only (not desktop)
          if (!isTablet && !useDesktopNav) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Grade arrows for mobile
                _buildGradePickerArrows(
                  isTablet: isTablet,
                  enabled: !hasPromotion,
                  useDesktopNav: useDesktopNav,
                ),
                const SizedBox(width: 8),
                _buildIconButton(
                  icon: Icons.delete_outline,
                  onTap: widget.onDelete,
                  isTablet: isTablet,
                  isDestructive: true,
                ),
                const SizedBox(width: 8),
                _buildCompactSaveButton(isTablet: isTablet),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCompactField({
    String? label,
    required TextEditingController controller,
    String? prefix,
    required bool isTablet,
    TextAlign textAlign = TextAlign.right,
    bool isNumber = false,
    int? maxDecimals,
    required Function(String) onChanged,
    bool enabled = true,
    FocusNode? focusNode,
    bool selectAllOnTap = false,
    bool useDesktopNav = false,
  }) {
    final fieldHeight = useDesktopNav ? 40.0 : (isTablet ? 52.0 : 30.0);
    final fontSize = useDesktopNav ? 12.0 : (isTablet ? 18.0 : 12.0);
    final horizontalPadding = useDesktopNav ? 6.0 : (isTablet ? 12.0 : 6.0);
    final verticalPadding = useDesktopNav ? 12.0 : (isTablet ? 14.0 : 6.0);
    
    // Build regex pattern based on maxDecimals
    final decimalPattern = maxDecimals != null
        ? r'^-?\d*\.?\d{0,' + maxDecimals.toString() + r'}'
        : r'^-?\d*\.?\d*';
    
    final textField = TextField(
      controller: controller,
      focusNode: focusNode,
      enabled: enabled,
      scrollPhysics: const ClampingScrollPhysics(),
      keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
      textAlign: textAlign,
      textAlignVertical: TextAlignVertical.center,
      maxLines: 1,
      minLines: 1,
      onTap: selectAllOnTap
          ? () {
              final text = controller.text;
              if (text.isNotEmpty) {
                controller.selection = TextSelection(
                  baseOffset: 0,
                  extentOffset: text.length,
                );
              }
            }
          : null,
      inputFormatters: isNumber
          ? [FilteringTextInputFormatter.allow(RegExp(r'^-?\d*'))]
          : [FilteringTextInputFormatter.allow(RegExp(decimalPattern))],
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
        color: enabled
            ? (widget.isDark ? Colors.white : Colors.black87)
            : (widget.isDark ? Colors.white38 : Colors.black38),
      ),
      decoration: InputDecoration(
        prefixText: prefix,
        prefixStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          color: enabled
              ? (widget.isDark ? Colors.white70 : Colors.black54)
              : (widget.isDark ? Colors.white30 : Colors.black26),
        ),
        isDense: true,
        constraints: BoxConstraints(
          minHeight: fieldHeight,
          maxHeight: fieldHeight,
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: verticalPadding,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(
            color: widget.isDark ? Colors.white24 : Colors.grey.shade300,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(
            color: widget.isDark ? Colors.white24 : Colors.grey.shade300,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(
            color: widget.isDark ? Colors.white12 : Colors.grey.shade200,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: kPrimaryColor),
        ),
        filled: true,
        fillColor: enabled
            ? (widget.isDark ? widget.colors.surface : Colors.white)
            : (widget.isDark ? widget.colors.surface.withOpacity(0.5) : Colors.grey.shade100),
      ),
      onChanged: onChanged,
    );

    // On tablet, wrap with MediaQuery to disable text scaling and prevent cutoff
    if (isTablet) {
      return MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
        child: textField,
      );
    }
    return textField;
  }

  Widget _buildDescriptionField(bool isTablet, {bool useDesktopNav = false}) {
    final fieldHeight = useDesktopNav ? 30.0 : (isTablet ? 52.0 : 32.0);
    final fontSize = useDesktopNav ? 12.0 : (isTablet ? 18.0 : 14.0);
    final textField = TextField(
      controller: _descriptionController,
      focusNode: _descriptionFocusNode,
      scrollPhysics: const ClampingScrollPhysics(),
      textAlignVertical: TextAlignVertical.center,
      maxLines: 1,
      minLines: 1,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
        color: widget.isDark ? Colors.white : Colors.black87,
      ),
      decoration: InputDecoration(
        isDense: true,
        constraints: BoxConstraints(
          minHeight: fieldHeight,
          maxHeight: fieldHeight,
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: useDesktopNav ? 8 : (isTablet ? 12 : 10),
          vertical: useDesktopNav ? 6 : (isTablet ? 14 : 8),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(
            color: widget.isDark ? Colors.white24 : Colors.grey.shade300,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(
            color: widget.isDark ? Colors.white24 : Colors.grey.shade300,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: kPrimaryColor),
        ),
        filled: true,
        fillColor: widget.isDark ? widget.colors.surface : Colors.white,
      ),
      onChanged: (value) {
        widget.onDescriptionChanged?.call(value);
      },
    );

    // On tablet or desktop, wrap with MediaQuery to disable text scaling and prevent cutoff
    if (isTablet || useDesktopNav) {
      return MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
        child: textField,
      );
    }
    return textField;
  }

  Widget _buildQtyButton({
    required IconData icon,
    required VoidCallback? onTap,
    required bool isTablet,
    bool enabled = true,
    bool useDesktopNav = false,
  }) {
    final width = useDesktopNav ? 28.0 : (isTablet ? 52.0 : 24.0);
    final height = useDesktopNav ? 34.0 : (isTablet ? 52.0 : 30.0);
    final iconSize = useDesktopNav ? 18.0 : (isTablet ? 26.0 : 16.0);
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: enabled
              ? kPrimaryColor.withOpacity(0.1)
              : (widget.isDark ? Colors.grey.shade800 : Colors.grey.shade200),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: enabled
                ? kPrimaryColor.withOpacity(0.3)
                : (widget.isDark ? Colors.white12 : Colors.grey.shade300),
          ),
        ),
        child: Icon(
          icon,
          size: iconSize,
          color: enabled
              ? kPrimaryColor
              : (widget.isDark ? Colors.white30 : Colors.grey.shade400),
        ),
      ),
    );
  }

  Widget _buildGradePickerArrows({
    required bool isTablet,
    required bool enabled,
    bool useDesktopNav = false,
  }) {
    final double height = useDesktopNav ? 34 : (isTablet ? 52 : 28);
    final double width = useDesktopNav ? 26 : (isTablet ? 32 : 24);
    final double iconSize = useDesktopNav ? 12 : (isTablet ? 18 : 12);
    final double iconGap = useDesktopNav ? 0 : (isTablet ? 2 : 0);

    return InkWell(
      onTap: enabled ? _showPricingGradeDialog : null,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: enabled
              ? (widget.isDark
                  ? widget.colors.surface
                  : Colors.grey.shade100)
              : (widget.isDark
                  ? widget.colors.surface.withOpacity(0.5)
                  : Colors.grey.shade200),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: widget.isDark ? Colors.white24 : Colors.grey.shade300,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.keyboard_arrow_up,
              size: iconSize,
              color: enabled ? kPrimaryColor : (widget.isDark ? Colors.white30 : Colors.grey.shade400),
            ),
            SizedBox(height: iconGap),
            Icon(
              Icons.keyboard_arrow_down,
              size: iconSize,
              color: enabled ? kPrimaryColor : (widget.isDark ? Colors.white30 : Colors.grey.shade400),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalculatorButton({
    required VoidCallback? onTap,
    required bool isTablet,
    bool enabled = true,
    bool useDesktopNav = false,
  }) {
    final size = useDesktopNav ? 34.0 : (isTablet ? 52.0 : 30.0);
    final iconSize = useDesktopNav ? 18.0 : (isTablet ? 22.0 : 14.0);
    final Color bgColor = widget.isDark ? widget.colors.surface : Colors.grey.shade100;
    final Color fgColor = enabled 
        ? (widget.isDark ? Colors.white70 : Colors.blueGrey.shade700)
        : (widget.isDark ? Colors.white30 : Colors.grey.shade400);
    final Color borderColor = widget.isDark ? Colors.white24 : Colors.grey.shade300;

    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: borderColor),
        ),
        child: Icon(
          Icons.calculate_outlined,
          size: iconSize,
          color: fgColor,
        ),
      ),
    );
  }

  Future<void> _openPriceCalculator(BuildContext context) async {
    FocusScope.of(context).unfocus();
    await Future.delayed(const Duration(milliseconds: 120));

    final item = widget.item;
    final double? result = await showDialog<double>(
      context: context,
      builder: (context) => PriceCalculatorDialog(
        incCost: item.computedCostInc,
        exCost: item.computedCostEx,
        currentSell: widget.isIncTax ? item.incPrice : item.exPrice,
      ),
    );

    if (result != null && mounted) {
      // The calculator returns the new sell price
      // We need to call onPriceChanged with the appropriate price
      widget.onPriceChanged(result);
    }
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onTap,
    required bool isTablet,
    bool isDestructive = false,
    bool hasValue = false,
    bool useDesktopNav = false,
  }) {
    final size = useDesktopNav ? 34.0 : (isTablet ? 52.0 : 30.0);
    final iconSize = useDesktopNav ? 18.0 : (isTablet ? 22.0 : 16.0);
    final Color bgColor = isDestructive
        ? kErrorColor.withOpacity(0.1)
        : hasValue
        ? kPrimaryColor.withOpacity(0.15)
        : (widget.isDark ? widget.colors.surface : Colors.grey.shade100);
    final Color fgColor = isDestructive
        ? kErrorColor
        : hasValue
        ? kPrimaryColor
        : (widget.isDark ? Colors.white70 : Colors.blueGrey.shade700);
    final Color borderColor = isDestructive
        ? kErrorColor.withOpacity(0.3)
        : hasValue
        ? kPrimaryColor.withOpacity(0.3)
        : (widget.isDark ? Colors.white24 : Colors.grey.shade300);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: borderColor),
        ),
        child: Icon(icon, size: iconSize, color: fgColor),
      ),
    );
  }

  Widget _buildSerialButton({
    required VoidCallback onTap,
    required bool isTablet,
    bool hasValue = false,
    bool useDesktopNav = false,
  }) {
    final size = useDesktopNav ? 34.0 : (isTablet ? 52.0 : 30.0);
    final Color bgColor = hasValue
        ? kPrimaryColor.withOpacity(0.15)
        : (widget.isDark ? widget.colors.surface : Colors.grey.shade100);
    final Color fgColor = hasValue
        ? kPrimaryColor
        : (widget.isDark ? Colors.white70 : Colors.blueGrey.shade700);
    final Color borderColor = hasValue
        ? kPrimaryColor.withOpacity(0.3)
        : (widget.isDark ? Colors.white24 : Colors.grey.shade300);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: borderColor),
        ),
        child: Center(
          child: Text(
            "S/N",
            style: TextStyle(
              fontSize: useDesktopNav ? 10 : (isTablet ? 14 : 10),
              fontWeight: FontWeight.w700,
              color: fgColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactSaveButton({required bool isTablet, bool useDesktopNav = false}) {
    final size = useDesktopNav ? 34.0 : (isTablet ? 52.0 : 30.0);
    return InkWell(
      onTap: widget.onSave,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: kPrimaryColor,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(Icons.check, size: useDesktopNav ? 18 : (isTablet ? 24 : 16), color: Colors.white),
      ),
    );
  }

  void _showSerialDialog(BuildContext context) async {
    final availableSerials = widget.item.stock?.serialNumbers ?? const <SerialNumberVO>[];

    final result = await SerialNumberDialog.show(
      context: context,
      barcode: widget.item.code,
      description: widget.item.description,
      targetQuantity: widget.item.qty.toInt(),
      availableSerials: availableSerials,
      initialSelected: widget.item.serialNumbers.isNotEmpty
          ? List<SerialNumberVO>.from(widget.item.serialNumbers)
          : null,
    );

    if (result != null) {
      widget.onSerialChanged(result);
    }
  }

  Widget _buildTaxGpButton({
    required VoidCallback onTap,
    required bool isTablet,
    bool useDesktopNav = false,
  }) {
    final size = useDesktopNav ? 34.0 : (isTablet ? 52.0 : 30.0);
    final iconSize = useDesktopNav ? 18.0 : (isTablet ? 22.0 : 14.0);
    final Color bgColor = widget.isDark ? widget.colors.surface : Colors.grey.shade100;
    final Color fgColor = widget.isDark ? Colors.white70 : Colors.blueGrey.shade700;
    final Color borderColor = widget.isDark ? Colors.white24 : Colors.grey.shade300;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: borderColor),
        ),
        child: Icon(
          Icons.trending_up,
          size: iconSize,
          color: fgColor,
        ),
      ),
    );
  }

  void _showItemTaxAndGpDialog(BuildContext context) {
    final isTablet = widget.isTablet;
    final isDark = widget.isDark;
    final colors = widget.colors;
    final item = widget.item;
    
    // Use Rational for precise calculations
    final qtyRational = Rational.parse(item.qty.toString());
    final incPriceRational = Rational.parse(item.incPrice.toString());
    final exPriceRational = Rational.parse(item.exPrice.toString());
    
    // Tax calculations with precise Rational arithmetic
    // Ex Tax: sellEx * qty
    final exTotalRational = exPriceRational * qtyRational;
    final double exTotal = exTotalRational.toDecimal(scaleOnInfinitePrecision: 10).toDouble();
    
    // Inc Tax: sellInc * qty
    final incTotalRational = incPriceRational * qtyRational;
    final double incTotal = incTotalRational.toDecimal(scaleOnInfinitePrecision: 10).toDouble();
    
    // Tax Amount: (sellInc - sellEx) * qty
    final taxPerUnitRational = incPriceRational - exPriceRational;
    final taxAmountRational = taxPerUnitRational * qtyRational;
    final double taxAmount = taxAmountRational.toDecimal(scaleOnInfinitePrecision: 10).toDouble();
    
    // GP calculations with precise Rational arithmetic
    // Cost depends on taxType: == 0 -> costEx, != 0 -> costInc
    final double itemCost = item.taxType == 0
        ? item.computedCostEx
        : item.computedCostInc;
    final costRational = Rational.parse(itemCost.toString());
    
    // Total Cost: cost * qty
    final totalCostRational = costRational * qtyRational;
    final double totalCost = totalCostRational.toDecimal(scaleOnInfinitePrecision: 10).toDouble();
    
    // Est. Gross Profit: (sellEx - cost) * qty
    final profitPerUnitRational = exPriceRational - costRational;
    final totalGpRational = profitPerUnitRational * qtyRational;
    final double totalGp = totalGpRational.toDecimal(scaleOnInfinitePrecision: 10).toDouble();

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (dialogContext) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: isTablet ? 500 : MediaQuery.of(context).size.width * 0.85,
              padding: EdgeInsets.all(isTablet ? 28 : 24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E2733) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.5 : 0.2),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Close button row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(dialogContext).pop(),
                        child: Icon(
                          Icons.close,
                          size: isTablet ? 26 : 24,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                  
                  // Tax Section
                  Text(
                    "Tax",
                    style: TextStyle(
                      fontSize: isTablet ? 16 : 14,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  SizedBox(height: isTablet ? 12 : 10),
                  TaxBreakdownWidget(
                    incTotal: incTotal,
                    exTotal: exTotal,
                    taxAmount: taxAmount,
                    colors: colors,
                    isDark: isDark,
                  ),
                  
                  SizedBox(height: isTablet ? 20 : 16),
                  Divider(color: isDark ? Colors.white24 : Colors.grey.shade300),
                  SizedBox(height: isTablet ? 16 : 12),
                  
                  // GP Section
                  Text(
                    "GP",
                    style: TextStyle(
                      fontSize: isTablet ? 16 : 14,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  SizedBox(height: isTablet ? 12 : 10),
                  ProfitBreakdownWidget(
                    totalEx: exTotal,
                    totalCost: totalCost,
                    totalGp: totalGp,
                    colors: colors,
                    isDark: isDark,
                  ),
                  SizedBox(height: isTablet ? 16 : 12),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Mobile-optimized cart tile with thumbnail, description and price
class MobileCartTile extends StatelessWidget {
  final CartItemVO item;
  final int index;
  final AppThemeColors colors;
  final bool isDark;
  final VoidCallback? onDelete;
  final bool isIncTax;
  final double taxRate;
  final bool hideBarcode;
  final bool hideCategories;
  final bool hideTaxCode;

  const MobileCartTile({
    super.key,
    required this.item,
    required this.index,
    required this.colors,
    required this.isDark,
    this.onDelete,
    this.isIncTax = true,
    this.taxRate = 0.1,
    this.hideBarcode = false,
    this.hideCategories = false,
    this.hideTaxCode = false,
  });

  double get _displayPrice =>
      isIncTax ? item.incPrice : item.exPrice;
  double get _displayExtension =>
      isIncTax ? item.extension : item.extensionEx;
    bool get _hasPromotion =>
      item.stock?.isOnPromotion == true &&
      item.stock?.promotion?.promotionRrp != null;

  /// Extract tax code from salesTax string (e.g., "GST 10%" -> "GST")
  String _extractTaxCode() {
    final salesTax = item.stock?.salesTax;
    if (salesTax == null || salesTax.isEmpty) return '';
    // Extract just the first word (the tax code)
    final parts = salesTax.trim().split(' ');
    return parts.isNotEmpty ? parts[0] : '';
  }

  /// Format categories as "Cat1 / Cat2 / Cat3"
  String _formatCategories() {
    final stock = item.stock;
    if (stock == null) return '';
    final cats = <String>[];
    if (stock.category1?.isNotEmpty == true) cats.add(stock.category1!);
    if (stock.category2?.isNotEmpty == true) cats.add(stock.category2!);
    if (stock.category3?.isNotEmpty == true) cats.add(stock.category3!);
    return cats.join(' / ');
  }

  @override
  Widget build(BuildContext context) {
    final bool useDesktopNav = context.useDesktopNav;
    
    // Desktop-specific font sizes (same as grid view)
    final double descFontSize = useDesktopNav ? 12 : 14;
    final double codeFontSize = useDesktopNav ? 11 : 13;
    final double qtyFontSize = useDesktopNav ? 11 : 13;
    final double extFontSize = useDesktopNav ? 12 : 14;
    
    // Desktop-specific sizing
    final double verticalPadding = useDesktopNav ? 0 : 8;
    final double thumbnailSize = useDesktopNav ? 36 : 38;
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: verticalPadding),
      decoration: BoxDecoration(
        color: isDark
            ? Color.lerp(colors.surface, Colors.white, 0.06)
            : kSecondaryColor,
        borderRadius: BorderRadius.circular(10),
        border: isDark
            ? Border.all(color: Colors.white.withOpacity(0.18))
            : null,
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.35)
                : kThirdColor.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Thumbnail Image
          Container(
            width: thumbnailSize,
            height: thumbnailSize,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              color: isDark ? colors.surface : Colors.white,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: item.stock?.imageUrl != null &&
                      item.stock!.imageUrl!.trim().isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: item.stock!.imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, _) =>
                          Image.asset(overviewPlaceholder, fit: BoxFit.fill),
                      errorWidget: (_, _, _) =>
                          Image.asset(overviewPlaceholder, fit: BoxFit.fill),
                    )
                  : Image.asset(overviewPlaceholder, fit: BoxFit.fill),
            ),
          ),
          // Item Details - Desktop uses evenly distributed columns
          if (useDesktopNav) ...[
            // Barcode (conditionally hidden)
            if (!hideBarcode)
              SizedBox(
                width: 100,
                child: Text(
                  item.code,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: codeFontSize,
                    fontWeight: FontWeight.w900,
                    color: kPrimaryColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            // Description
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Text(
                  item.description,
                  style: TextStyle(
                    fontSize: descFontSize,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            // Categories (conditionally hidden)
            if (!hideCategories)
              SizedBox(
                width: 120,
                child: Text(
                  _formatCategories().isNotEmpty ? _formatCategories() : '-',
                  style: TextStyle(
                    fontSize: codeFontSize,
                    color: isDark ? Colors.white60 : Colors.grey.shade600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            // Tax Code (conditionally hidden)
            if (!hideTaxCode)
              SizedBox(
                width: 50,
                child: Text(
                  _extractTaxCode().isNotEmpty ? _extractTaxCode() : '-',
                  style: TextStyle(
                    fontSize: codeFontSize,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white60 : Colors.grey.shade700,
                  ),
                ),
              ),
            // Qty
            SizedBox(
              width: 50,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark ? colors.surface : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  formatQtyForDisplay(item.qty, item.stock?.allowFractions ?? false),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: qtyFontSize,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white70 : Colors.blueGrey.shade700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Extension Total
            SizedBox(
              width: 90,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (_hasPromotion)
                    Text(
                      "(*Promotion)",
                      style: TextStyle(
                        fontSize: 10,
                        color: kErrorColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  Text(
                    FormattingUtils.formatCurrencyWithDecimals(
                      _displayExtension,
                      2,
                    ),
                    style: TextStyle(
                      fontSize: extFontSize,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            // Mobile layout - original
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.description,
                    style: TextStyle(
                      fontSize: descFontSize,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.code,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: codeFontSize,
                      fontWeight: FontWeight.w900,
                      color: kPrimaryColor,
                    ),
                  ),
                ],
              ),
            ),
            // Mobile Qty & Extension
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? colors.surface : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    formatQtyForDisplay(item.qty, item.stock?.allowFractions ?? false),
                    style: TextStyle(
                      fontSize: qtyFontSize,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white70 : Colors.blueGrey.shade700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (_hasPromotion)
                      Text(
                        "(*Promotion)",
                        style: TextStyle(
                          fontSize: 10,
                          color: kErrorColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    Text(
                      FormattingUtils.formatCurrencyWithDecimals(
                        _displayExtension,
                        2,
                      ),
                      style: TextStyle(
                        fontSize: extFontSize,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Tablet-optimized cart tile with grid layout
class TabletCartTile extends StatelessWidget {
  final CartItemVO item;
  final int index;
  final AppThemeColors colors;
  final bool isDark;
  final VoidCallback? onDelete;
  final bool isIncTax;
  final double taxRate;
  final bool hideBarcode;
  final bool hideCategories;
  final bool hideTaxCode;

  const TabletCartTile({
    super.key,
    required this.item,
    required this.index,
    required this.colors,
    required this.isDark,
    this.onDelete,
    this.isIncTax = true,
    this.taxRate = 0.1,
    this.hideBarcode = false,
    this.hideCategories = false,
    this.hideTaxCode = false,
  });

  double get _displayPrice =>
      isIncTax ? item.incPrice : item.exPrice;
  double get _displayExtension =>
      isIncTax ? item.extension : item.extensionEx;
    bool get _hasPromotion =>
      item.stock?.isOnPromotion == true &&
      item.stock?.promotion?.promotionRrp != null;

  String get _formattedPrice => formatSellPriceForDisplay(_displayPrice);

  /// Extract tax code from salesTax string (e.g., "GST 10%" -> "GST")
  String _extractTaxCode() {
    final salesTax = item.stock?.salesTax;
    if (salesTax == null || salesTax.isEmpty) return '';
    final parts = salesTax.trim().split(' ');
    return parts.isNotEmpty ? parts[0] : '';
  }

  /// Format categories as "Cat1 / Cat2 / Cat3"
  String _formatCategories() {
    final stock = item.stock;
    if (stock == null) return '';
    final cats = <String>[];
    if (stock.category1?.isNotEmpty == true) cats.add(stock.category1!);
    if (stock.category2?.isNotEmpty == true) cats.add(stock.category2!);
    if (stock.category3?.isNotEmpty == true) cats.add(stock.category3!);
    return cats.join(' / ');
  }

  @override
  Widget build(BuildContext context) {
    final bool useDesktopNav = context.useDesktopNav;
    
    // Desktop-specific font sizes (same as grid view)
    final double descFontSize = useDesktopNav ? 12 : 14;
    final double codeFontSize = useDesktopNav ? 11 : 13;
    final double priceFontSize = useDesktopNav ? 11 : 14;
    final double qtyFontSize = useDesktopNav ? 11 : 14;
    final double extFontSize = useDesktopNav ? 12 : 15;
    
    // Desktop-specific sizing
    final double verticalPadding = useDesktopNav ? 6 : 8;
    final double thumbnailSize = useDesktopNav ? 36 : 45;
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: verticalPadding),
      decoration: BoxDecoration(
        color: isDark
            ? Color.lerp(colors.surface, Colors.white, 0.06)
            : kSecondaryColor,
        borderRadius: BorderRadius.circular(10),
        border: isDark
            ? Border.all(color: Colors.white.withOpacity(0.18))
            : null,
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.35)
                : kThirdColor.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Thumbnail Image
          Container(
            width: thumbnailSize,
            height: thumbnailSize,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              color: isDark ? colors.surface : Colors.white,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: item.stock?.imageUrl != null &&
                      item.stock!.imageUrl!.trim().isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: item.stock!.imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, _) =>
                          Image.asset(overviewPlaceholder, fit: BoxFit.fill),
                      errorWidget: (_, _, _) =>
                          Image.asset(overviewPlaceholder, fit: BoxFit.fill),
                    )
                  : Image.asset(overviewPlaceholder, fit: BoxFit.fill),
            ),
          ),
          // Desktop layout with evenly distributed columns
          if (useDesktopNav) ...[
            // Barcode (conditionally hidden)
            if (!hideBarcode)
              Expanded(
                flex: 1,
                child: Text(
                  item.code,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w900,
                    color: kPrimaryColor,
                    fontSize: codeFontSize,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            // Description
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Text(
                  item.description,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: descFontSize,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            // Categories (conditionally hidden)
            if (!hideCategories)
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Text(
                    _formatCategories().isNotEmpty ? _formatCategories() : '-',
                    style: TextStyle(
                      fontSize: codeFontSize,
                      color: isDark ? Colors.white60 : Colors.grey.shade600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            // Tax Code (conditionally hidden)
            if (!hideTaxCode)
              Transform.translate(
                offset: const Offset(-150, 0),
                child: SizedBox(
                  width: 40,
                  child: Text(
                    _extractTaxCode().isNotEmpty ? _extractTaxCode() : '-',
                    style: TextStyle(
                      fontSize: codeFontSize,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white60 : Colors.grey.shade700,
                    ),
                  ),
                ),
              ),
            // Base Sell Price
            Transform.translate(
              offset: const Offset(-100, 0),
              child: SizedBox(
                width: 80,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (_hasPromotion)
                      Text(
                        "(*Promo)",
                        style: TextStyle(
                          fontSize: 9,
                          color: kErrorColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    Text(
                      "\$$_formattedPrice",
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: colors.onSurfaceMuted,
                        fontSize: priceFontSize,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Qty
            Transform.translate(
              offset: const Offset(-50, 0),
              child: SizedBox(
                width: 60,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? colors.surface : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      formatQtyForDisplay(item.qty, item.stock?.allowFractions ?? false),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: qtyFontSize,
                        color: isDark ? Colors.white70 : Colors.blueGrey.shade700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Extension Total
            SizedBox(
              width: 100,
              child: Text(
                FormattingUtils.formatCurrencyWithDecimals(
                  _displayExtension,
                  2,
                ),
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: extFontSize,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
          ] else ...[
            // Tablet/Mobile layout
            Expanded(
              flex: 2,
              child: Text(
                item.code,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w900,
                  color: kPrimaryColor,
                  fontSize: codeFontSize,
                ),
              ),
            ),
            Expanded(
              flex: 4,
              child: Text(
                item.description,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: descFontSize,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(
              width: 120,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (_hasPromotion)
                    Text(
                      "(*Promotion)",
                      style: TextStyle(
                        fontSize: 10,
                        color: kErrorColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  Text(
                    "\$$_formattedPrice",
                    textAlign: TextAlign.right,
                    style: TextStyle(color: colors.onSurfaceMuted, fontSize: priceFontSize),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 120,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? colors.surface : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    formatQtyForDisplay(item.qty, item.stock?.allowFractions ?? false),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: qtyFontSize,
                      color: isDark ? Colors.white70 : Colors.blueGrey.shade700,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(
              width: 130,
              child: Text(
                FormattingUtils.formatCurrencyWithDecimals(
                  _displayExtension,
                  2,
                ),
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: extFontSize,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Compact cart tile - table row style without thumbnails
class CompactCartTile extends StatelessWidget {
  final CartItemVO item;
  final int index;
  final AppThemeColors colors;
  final bool isDark;
  final bool isIncTax;
  final double taxRate;
  final bool hideBarcode;
  final bool hideCategories;
  final bool hideTaxCode;

  const CompactCartTile({
    super.key,
    required this.item,
    required this.index,
    required this.colors,
    required this.isDark,
    this.isIncTax = true,
    this.taxRate = 0.1,
    this.hideBarcode = false,
    this.hideCategories = false,
    this.hideTaxCode = false,
  });

  double get _displayExtension =>
      isIncTax ? item.extension : item.extensionEx;

  /// Extract tax code from salesTax string (e.g., "GST 10%" -> "GST")
  String _extractTaxCode() {
    final salesTax = item.stock?.salesTax;
    if (salesTax == null || salesTax.isEmpty) return '';
    final parts = salesTax.trim().split(' ');
    return parts.isNotEmpty ? parts[0] : '';
  }

  /// Format categories as "Cat1 / Cat2 / Cat3"
  String _formatCategories() {
    final stock = item.stock;
    if (stock == null) return '';
    final cats = <String>[];
    if (stock.category1?.isNotEmpty == true) cats.add(stock.category1!);
    if (stock.category2?.isNotEmpty == true) cats.add(stock.category2!);
    if (stock.category3?.isNotEmpty == true) cats.add(stock.category3!);
    return cats.join(' / ');
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = context.isTablet;
    final useDesktopNav = context.useDesktopNav;

    // Desktop uses evenly distributed columns
    if (useDesktopNav) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: Row(
              children: [
                // Barcode (conditionally hidden)
                if (!hideBarcode)
                  Expanded(
                    flex: 1,
                    child: Text(
                      item.code,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: kPrimaryColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                // Description
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 50),
                    child: Text(
                      item.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                // Categories (conditionally hidden)
                if (!hideCategories)
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Text(
                        _formatCategories(),
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white60 : Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                // Tax Code (conditionally hidden)
                if (!hideTaxCode)
                  Transform.translate(
                    offset: const Offset(-150, 0),
                    child: SizedBox(
                      width: 40,
                      child: Text(
                        _extractTaxCode(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white60 : Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ),
                // Qty
                Transform.translate(
                  offset: const Offset(-80, 0),
                  child: SizedBox(
                    width: 60,
                    child: Text(
                      formatQtyForDisplay(item.qty, item.stock?.allowFractions ?? false),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : Colors.blueGrey.shade700,
                      ),
                    ),
                  ),
                ),
                // Price
                SizedBox(
                  width: 100,
                  child: Text(
                    FormattingUtils.formatCurrencyWithDecimals(
                      _displayExtension,
                      2,
                    ),
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            thickness: 1,
            color: isDark ? Colors.white24 : Colors.grey.shade400,
          ),
        ],
      );
    }

    // Mobile/Tablet layout (unchanged)
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? 16 : 10,
            vertical: isTablet ? 8 : 4,
          ),
          child: Row(
            children: [
              // Code
              SizedBox(
                width: isTablet ? 140 : 75,
                child: Text(
                  item.code,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: isTablet ? 13 : 11,
                    fontWeight: FontWeight.w900,
                    color: kPrimaryColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: isTablet ? 48 : 0),
              // Description
              Expanded(
                child: Text(
                  item.description,
                  style: TextStyle(
                    fontSize: isTablet ? 14 : 12,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Qty
              SizedBox(
                width: isTablet ? 80 : 30,
                child: Text(
                  formatQtyForDisplay(item.qty, item.stock?.allowFractions ?? false),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isTablet ? 15 : 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : Colors.blueGrey.shade700,
                  ),
                ),
              ),
              // Price
              SizedBox(
                width: isTablet ? 130 : 65,
                child: Text(
                  FormattingUtils.formatCurrencyWithDecimals(
                    _displayExtension,
                    2,
                  ),
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: isTablet ? 15 : 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
        Divider(
          height: 1,
          thickness: 1,
          color: isDark ? Colors.white24 : Colors.grey.shade400,
        ),
      ],
    );
  }
}

/// Grid header for tablet view
class CartGridHeader extends StatelessWidget {
  final AppThemeColors colors;

  const CartGridHeader({super.key, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Space for thumbnail (45 + 12 margin)
        const SizedBox(width: 57),
        Expanded(flex: 2, child: _buildHeader("Code")),
        Expanded(flex: 4, child: _buildHeader("Description")),
        SizedBox(width: 120, child: _buildHeader("Price", alignRight: true)),
        SizedBox(width: 120, child: _buildHeader("Qty", alignCenter: true)),
        SizedBox(width: 130, child: _buildHeader("Ext", alignRight: true)),
      ],
    );
  }

  Widget _buildHeader(
    String title, {
    bool alignRight = false,
    bool alignCenter = false,
  }) {
    return Text(
      title,
      textAlign: alignCenter
          ? TextAlign.center
          : (alignRight ? TextAlign.right : TextAlign.left),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: colors.onSurfaceMuted,
      ),
    );
  }
}
