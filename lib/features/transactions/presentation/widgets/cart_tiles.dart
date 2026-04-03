import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../constants/colors.dart';
import '../../../../constants/images.dart';
import '../../../../constants/theme_colors.dart';
import '../../../../entities/vos/cart_item_vo.dart';
import '../../../../utils/responsive_utils.dart';
import 'serial_number_dialog.dart';
import 'breakdown_widgets.dart';

/// Helper to format sell price - shows 4 decimals if the price has significant 
/// digits beyond 2 decimal places, otherwise shows 2 decimals
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
  final Function(String serial) onSerialChanged;
  final Function(String description)? onDescriptionChanged;
  final VoidCallback onSave;
  final VoidCallback onDelete;
  final bool isIncTax;
  final double taxRate;
  final bool roundSellPriceTo2Decimals;
  final bool allowPriceEdit;

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
    this.roundSellPriceTo2Decimals = false,
    this.allowPriceEdit = true,
  });

  @override
  State<ExpandedEditCartTile> createState() => _ExpandedEditCartTileState();
}

class _ExpandedEditCartTileState extends State<ExpandedEditCartTile> {
  late TextEditingController _qtyController;
  late TextEditingController _priceController;
  late TextEditingController _serialController;
  late TextEditingController _descriptionController;

  bool get _allowRenaming => widget.item.stock?.allowRenaming ?? false;
  bool get _allowFractions => widget.item.stock?.allowFractions ?? false;

  int get _priceDecimalPlaces => widget.roundSellPriceTo2Decimals ? 2 : 4;

  /// Format qty for display - always 3 decimals for fractional items, integer for others
  String _formatQty(double qty) {
    if (_allowFractions) {
      return qty.toStringAsFixed(3);
    }
    return qty.toInt().toString();
  }

  String _formatSellPrice(double price) {
    if (widget.roundSellPriceTo2Decimals) {
      return price.toStringAsFixed(2);
    }
    // Show 4 decimals if it has significant digits beyond 2 decimals
    final fixed4 = price.toStringAsFixed(4);
    final fixed2 = price.toStringAsFixed(2);
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
    _serialController = TextEditingController(
      text: widget.item.serialNumber ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.item.description,
    );
  }

  @override
  void didUpdateWidget(ExpandedEditCartTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.qty != widget.item.qty) {
      _qtyController.text = _formatQty(widget.item.qty);
    }
    // Update price when incPrice/exPrice changes or tax toggle changes
    final oldDisplayPrice = oldWidget.isIncTax
        ? oldWidget.item.incPrice
        : oldWidget.item.exPrice;
    if (oldDisplayPrice != _displayPrice || oldWidget.isIncTax != widget.isIncTax) {
      _priceController.text = _formatSellPrice(_displayPrice);
    }
    if (oldWidget.item.description != widget.item.description) {
      _descriptionController.text = widget.item.description;
    }
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _priceController.dispose();
    _serialController.dispose();
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

  @override
  Widget build(BuildContext context) {
    final isTablet = widget.isTablet;

    return Container(
      padding: EdgeInsets.all(isTablet ? 12 : 10),
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
                width: isTablet ? 44 : 36,
                height: isTablet ? 44 : 36,
                margin: EdgeInsets.only(right: isTablet ? 10 : 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: widget.isDark ? widget.colors.surface : Colors.white,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: widget.item.stock?.imageUrl != null
                      ? Image.network(
                          widget.item.stock!.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Image.asset(
                                overviewPlaceholder,
                                fit: BoxFit.fill,
                              ),
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
                      _buildDescriptionField(isTablet)
                    else
                      Text(
                        widget.item.description,
                        style: TextStyle(
                          fontSize: 14,
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
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: kPrimaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: isTablet ? 12 : 8),
              // Total display
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Total",
                    style: TextStyle(
                      fontSize: isTablet ? 10 : 9,
                      color: widget.colors.onSurfaceMuted,
                    ),
                  ),
                  Text(
                    "\$${_displayExtension.toStringAsFixed(2)}",
                    style: TextStyle(
                      fontSize: isTablet ? 15 : 13,
                      fontWeight: FontWeight.bold,
                      color: widget.isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
            ],
          ),

          SizedBox(height: isTablet ? 10 : 8),

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
                    children: [
                      // Action buttons
                      if (widget.item.trackSerial) ...[
                        _buildSerialButton(
                          onTap: () => _showSerialDialog(context),
                          isTablet: isTablet,
                          hasValue: widget.item.serialNumber?.isNotEmpty == true,
                        ),
                        SizedBox(width: isTablet ? 6 : 4),
                      ],

                      // Tax button
                      _buildTaxButton(
                        onTap: () => _showItemTaxDialog(context),
                        isTablet: isTablet,
                      ),
                      SizedBox(width: isTablet ? 6 : 4),

                      // Sell Price field
                      SizedBox(
                        width: isTablet ? 180 : 70,
                        height: isTablet ? 52 : 30,
                        child: _buildCompactField(
                          label: "Price",
                          controller: _priceController,
                          prefix: "\$",
                          isTablet: isTablet,
                          maxDecimals: _priceDecimalPlaces,
                          enabled: widget.allowPriceEdit,
                          onChanged: (value) {
                            final price = double.tryParse(value);
                            if (price != null) widget.onPriceChanged(price);
                          },
                        ),
                      ),

                      SizedBox(width: isTablet ? 20 : 8),

                      // Qty with +/- buttons
                      _buildQtyButton(
                        icon: Icons.remove,
                        onTap: _decrementQty,
                        isTablet: isTablet,
                      ),
                      SizedBox(width: isTablet ? 10 : 3),
                      SizedBox(
                        width: isTablet ? 90 : 40,
                        height: isTablet ? 52 : 30,
                        child: _buildCompactField(
                          controller: _qtyController,
                          isTablet: isTablet,
                          textAlign: TextAlign.center,
                          isNumber: !_allowFractions,
                          maxDecimals: _allowFractions ? 3 : null,
                          onChanged: (value) {
                            final qty = double.tryParse(value);
                            if (qty != null && qty != 0) widget.onQtyChanged(qty);
                          },
                        ),
                      ),
                      SizedBox(width: isTablet ? 10 : 3),
                      _buildQtyButton(
                        icon: Icons.add,
                        onTap: _incrementQty,
                        isTablet: isTablet,
                      ),

                      SizedBox(width: isTablet ? 6 : 4),

                      _buildIconButton(
                        icon: Icons.delete_outline,
                        onTap: widget.onDelete,
                        isTablet: isTablet,
                        isDestructive: true,
                      ),

                      SizedBox(width: isTablet ? 6 : 4),

                      // Save button
                      _buildCompactSaveButton(isTablet: isTablet),
                    ],
                  ),
                ),
              ),
            ],
          ),
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
  }) {
    final fieldHeight = isTablet ? 52.0 : 30.0;
    
    // Build regex pattern based on maxDecimals
    final decimalPattern = maxDecimals != null
        ? r'^-?\d*\.?\d{0,' + maxDecimals.toString() + r'}'
        : r'^-?\d*\.?\d*';
    
    final textField = TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
      textAlign: textAlign,
      textAlignVertical: TextAlignVertical.center,
      maxLines: 1,
      minLines: 1,
      inputFormatters: isNumber
          ? [FilteringTextInputFormatter.allow(RegExp(r'^-?\d*'))]
          : [FilteringTextInputFormatter.allow(RegExp(decimalPattern))],
      style: TextStyle(
        fontSize: isTablet ? 18 : 12,
        fontWeight: FontWeight.w600,
        color: enabled
            ? (widget.isDark ? Colors.white : Colors.black87)
            : (widget.isDark ? Colors.white38 : Colors.black38),
      ),
      decoration: InputDecoration(
        prefixText: prefix,
        prefixStyle: TextStyle(
          fontSize: isTablet ? 18 : 12,
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
          horizontal: isTablet ? 12 : 6,
          vertical: isTablet ? 14 : 6,
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

  Widget _buildDescriptionField(bool isTablet) {
    final fieldHeight = isTablet ? 52.0 : 32.0;
    final textField = TextField(
      controller: _descriptionController,
      textAlignVertical: TextAlignVertical.center,
      maxLines: 1,
      minLines: 1,
      style: TextStyle(
        fontSize: isTablet ? 18 : 14,
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
          horizontal: isTablet ? 12 : 10,
          vertical: isTablet ? 14 : 8,
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

    // On tablet, wrap with MediaQuery to disable text scaling and prevent cutoff
    if (isTablet) {
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
  }) {
    final size = isTablet ? 52.0 : 30.0;
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: size,
        height: size,
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
          size: isTablet ? 26 : 16,
          color: enabled
              ? kPrimaryColor
              : (widget.isDark ? Colors.white30 : Colors.grey.shade400),
        ),
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onTap,
    required bool isTablet,
    bool isDestructive = false,
    bool hasValue = false,
  }) {
    final size = isTablet ? 52.0 : 30.0;
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
        child: Icon(icon, size: isTablet ? 22 : 16, color: fgColor),
      ),
    );
  }

  Widget _buildSerialButton({
    required VoidCallback onTap,
    required bool isTablet,
    bool hasValue = false,
  }) {
    final size = isTablet ? 52.0 : 30.0;
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
              fontSize: isTablet ? 14 : 10,
              fontWeight: FontWeight.w700,
              color: fgColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactSaveButton({required bool isTablet}) {
    final size = isTablet ? 52.0 : 30.0;
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
        child: Icon(Icons.check, size: isTablet ? 24 : 16, color: Colors.white),
      ),
    );
  }

  void _showSerialDialog(BuildContext context) async {
    // For now, generate sample serials for demonstration
    final sampleSerials = List.generate(
      10,
      (i) => SerialItem(
        serialNumber: 'SN-${widget.item.code}-${1000 + i}',
        ageInDays: (i + 1) * 15,
        warrantyExpiry: DateTime.now().add(Duration(days: 365 - (i * 30))),
      ),
    );

    final result = await SerialNumberDialog.show(
      context: context,
      barcode: widget.item.code,
      description: widget.item.description,
      targetQuantity: widget.item.qty.toInt(),
      availableSerials: sampleSerials,
      initialSelected: widget.item.serialNumber?.isNotEmpty == true
          ? [widget.item.serialNumber!]
          : null,
    );

    if (result != null && result.isNotEmpty) {
      // Join multiple serials with comma if qty > 1
      widget.onSerialChanged(result.join(', '));
      _serialController.text = result.join(', ');
    }
  }

  Widget _buildTaxButton({
    required VoidCallback onTap,
    required bool isTablet,
  }) {
    final size = isTablet ? 52.0 : 30.0;
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
          Icons.receipt_long_outlined,
          size: isTablet ? 22 : 14,
          color: fgColor,
        ),
      ),
    );
  }

  void _showItemTaxDialog(BuildContext context) {
    final isTablet = widget.isTablet;
    final isDark = widget.isDark;
    final colors = widget.colors;
    final item = widget.item;
    
    // Calculate tax values for this item
    final double incTotal = item.extension;
    final double exTotal = item.extensionEx;
    final double taxAmount = incTotal - exTotal;

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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Item Tax",
                        style: TextStyle(
                          fontSize: isTablet ? 20 : 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
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
                  SizedBox(height: isTablet ? 16 : 12),
                  // Item description
                  Text(
                    item.description,
                    style: TextStyle(
                      fontSize: isTablet ? 14 : 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: isTablet ? 20 : 16),
                  TaxBreakdownWidget(
                    incTotal: incTotal,
                    exTotal: exTotal,
                    taxAmount: taxAmount,
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

  const MobileCartTile({
    super.key,
    required this.item,
    required this.index,
    required this.colors,
    required this.isDark,
    this.onDelete,
    this.isIncTax = true,
    this.taxRate = 0.1,
  });

  double get _displayPrice =>
      isIncTax ? item.incPrice : item.exPrice;
  double get _displayExtension =>
      isIncTax ? item.extension : item.extensionEx;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
            width: 38,
            height: 38,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              color: isDark ? colors.surface : Colors.white,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: item.stock?.imageUrl != null
                  ? Image.network(
                      item.stock!.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          Image.asset(overviewPlaceholder, fit: BoxFit.fill),
                    )
                  : Image.asset(overviewPlaceholder, fit: BoxFit.fill),
            ),
          ),
          // Item Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.description,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  item.code,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: kPrimaryColor,
                  ),
                ),
              ],
            ),
          ),

          // Quantity & Extension Total
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Qty Display
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? colors.surface : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  formatQtyForDisplay(item.qty, item.stock?.allowFractions ?? false),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white70 : Colors.blueGrey.shade700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Extension Total
              Text(
                "\$${_displayExtension.toStringAsFixed(2)}",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
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
  final bool roundSellPriceTo2Decimals;

  const TabletCartTile({
    super.key,
    required this.item,
    required this.index,
    required this.colors,
    required this.isDark,
    this.onDelete,
    this.isIncTax = true,
    this.taxRate = 0.1,
    this.roundSellPriceTo2Decimals = false,
  });

  double get _displayPrice =>
      isIncTax ? item.incPrice : item.exPrice;
  double get _displayExtension =>
      isIncTax ? item.extension : item.extensionEx;

  String get _formattedPrice => roundSellPriceTo2Decimals
      ? _displayPrice.toStringAsFixed(2)
      : formatSellPriceForDisplay(_displayPrice);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
            width: 45,
            height: 45,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              color: isDark ? colors.surface : Colors.white,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: item.stock?.imageUrl != null
                  ? Image.network(
                      item.stock!.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          Image.asset(overviewPlaceholder, fit: BoxFit.fill),
                    )
                  : Image.asset(overviewPlaceholder, fit: BoxFit.fill),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              item.code,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontWeight: FontWeight.w900,
                color: kPrimaryColor,
                fontSize: 13,
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
                fontSize: 14,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: 120,
            child: Text(
              "\$$_formattedPrice",
              textAlign: TextAlign.right,
              style: TextStyle(color: colors.onSurfaceMuted, fontSize: 14),
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
                    fontSize: 14,
                    color: isDark ? Colors.white70 : Colors.blueGrey.shade700,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 130,
            child: Text(
              "\$${_displayExtension.toStringAsFixed(2)}",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
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

  const CompactCartTile({
    super.key,
    required this.item,
    required this.index,
    required this.colors,
    required this.isDark,
    this.isIncTax = true,
    this.taxRate = 0.1,
  });

  double get _displayExtension =>
      isIncTax ? item.extension : item.extensionEx;

  @override
  Widget build(BuildContext context) {
    final isTablet = context.isTablet;

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
                  "\$${_displayExtension.toStringAsFixed(2)}",
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
