import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../constants/colors.dart';
import '../../../../constants/images.dart';
import '../../../../constants/theme_colors.dart';
import '../../../../entities/vos/cart_item_vo.dart';
import 'serial_number_dialog.dart';

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
  final Function(int qty) onQtyChanged;
  final Function(double price) onPriceChanged;
  final Function(String serial) onSerialChanged;
  final VoidCallback onSave;
  final VoidCallback onDelete;
  final bool isIncTax;
  final double taxRate;

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
    required this.onSave,
    required this.onDelete,
    this.isIncTax = true,
    this.taxRate = 0.1,
  });

  @override
  State<ExpandedEditCartTile> createState() => _ExpandedEditCartTileState();
}

class _ExpandedEditCartTileState extends State<ExpandedEditCartTile> {
  late TextEditingController _qtyController;
  late TextEditingController _priceController;
  late TextEditingController _serialController;

  @override
  void initState() {
    super.initState();
    _qtyController = TextEditingController(text: widget.item.qty.toString());
    _priceController = TextEditingController(
      text: widget.item.sellPrice.toStringAsFixed(2),
    );
    _serialController = TextEditingController(
      text: widget.item.serialNumber ?? '',
    );
  }

  @override
  void didUpdateWidget(ExpandedEditCartTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.qty != widget.item.qty) {
      _qtyController.text = widget.item.qty.toString();
    }
    if (oldWidget.item.sellPrice != widget.item.sellPrice) {
      _priceController.text = widget.item.sellPrice.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _priceController.dispose();
    _serialController.dispose();
    super.dispose();
  }

  double get _displayExtension => widget.isIncTax 
      ? widget.item.extension 
      : widget.item.extension / (1 + widget.taxRate);

  void _incrementQty() {
    final current = int.tryParse(_qtyController.text) ?? 1;
    final newQty = current + 1;
    _qtyController.text = newQty.toString();
    widget.onQtyChanged(newQty);
  }

  void _decrementQty() {
    final current = int.tryParse(_qtyController.text) ?? 1;
    if (current > 1) {
      final newQty = current - 1;
      _qtyController.text = newQty.toString();
      widget.onQtyChanged(newQty);
    }
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
        border: Border.all(
          color: kPrimaryColor.withOpacity(0.3),
          width: 1,
        ),
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
                          errorBuilder: (context, error, stackTrace) => Image.asset(
                            overviewPlaceholder,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Image.asset(
                          overviewPlaceholder,
                          fit: BoxFit.cover,
                        ),
                ),
              ),
              // Item details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.item.description,
                      style: TextStyle(
                        fontSize: isTablet ? 13 : 12,
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
                        fontSize: isTablet ? 11 : 10,
                        color: kPrimaryColor,
                      ),
                    ),
                  ],
                ),
              ),
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
          
          // Edit fields and actions row
          Row(
            children: [
              // Sell Price field
              SizedBox(
                width: isTablet ? 90 : 70,
                child: _buildCompactField(
                  label: "Price",
                  controller: _priceController,
                  prefix: "\$",
                  isTablet: isTablet,
                  onChanged: (value) {
                    final price = double.tryParse(value);
                    if (price != null) widget.onPriceChanged(price);
                  },
                ),
              ),
              
              SizedBox(width: isTablet ? 10 : 8),
              
              // Qty with +/- buttons
              _buildQtyButton(
                icon: Icons.remove,
                onTap: _decrementQty,
                isTablet: isTablet,
              ),
              SizedBox(width: isTablet ? 4 : 3),
              SizedBox(
                width: isTablet ? 50 : 40,
                child: _buildCompactField(
                  controller: _qtyController,
                  isTablet: isTablet,
                  textAlign: TextAlign.center,
                  isNumber: true,
                  onChanged: (value) {
                    final qty = int.tryParse(value);
                    if (qty != null && qty > 0) widget.onQtyChanged(qty);
                  },
                ),
              ),
              SizedBox(width: isTablet ? 4 : 3),
              _buildQtyButton(
                icon: Icons.add,
                onTap: _incrementQty,
                isTablet: isTablet,
              ),
              
              const Spacer(),
              
              // Action buttons
              if (widget.item.trackSerial) ...[
                _buildIconButton(
                  icon: Icons.qr_code,
                  onTap: () => _showSerialDialog(context),
                  isTablet: isTablet,
                  hasValue: widget.item.serialNumber?.isNotEmpty == true,
                ),
                SizedBox(width: isTablet ? 6 : 4),
              ],
              
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
    required Function(String) onChanged,
  }) {
    return SizedBox(
      height: isTablet ? 34 : 30,
      child: TextField(
        controller: controller,
        keyboardType: isNumber 
            ? TextInputType.number 
            : const TextInputType.numberWithOptions(decimal: true),
        textAlign: textAlign,
        inputFormatters: isNumber ? [FilteringTextInputFormatter.digitsOnly] : null,
        style: TextStyle(
          fontSize: isTablet ? 13 : 12,
          fontWeight: FontWeight.w600,
          color: widget.isDark ? Colors.white : Colors.black87,
        ),
        decoration: InputDecoration(
          prefixText: prefix,
          prefixStyle: TextStyle(
            fontSize: isTablet ? 13 : 12,
            fontWeight: FontWeight.w600,
            color: widget.isDark ? Colors.white70 : Colors.black54,
          ),
          isDense: true,
          contentPadding: EdgeInsets.symmetric(
            horizontal: isTablet ? 8 : 6,
            vertical: isTablet ? 8 : 6,
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
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: kPrimaryColor),
          ),
          filled: true,
          fillColor: widget.isDark ? widget.colors.surface : Colors.white,
        ),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildQtyButton({
    required IconData icon,
    required VoidCallback onTap,
    required bool isTablet,
  }) {
    final size = isTablet ? 34.0 : 30.0;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: kPrimaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: kPrimaryColor.withOpacity(0.3)),
        ),
        child: Icon(
          icon,
          size: isTablet ? 18 : 16,
          color: kPrimaryColor,
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
    final size = isTablet ? 34.0 : 30.0;
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
        child: Icon(icon, size: isTablet ? 18 : 16, color: fgColor),
      ),
    );
  }

  Widget _buildCompactSaveButton({required bool isTablet}) {
    final height = isTablet ? 34.0 : 30.0;
    return InkWell(
      onTap: widget.onSave,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        height: height,
        padding: EdgeInsets.symmetric(horizontal: isTablet ? 14 : 12),
        decoration: BoxDecoration(
          color: kPrimaryColor,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check, size: isTablet ? 16 : 14, color: Colors.white),
            SizedBox(width: isTablet ? 4 : 3),
            Text(
              "Save",
              style: TextStyle(
                fontSize: isTablet ? 12 : 11,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSerialDialog(BuildContext context) async {
    // TODO: In production, fetch available serials from database
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
      targetQuantity: widget.item.qty,
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

  double get _displayPrice => isIncTax ? item.sellPrice : item.sellPrice / (1 + taxRate);
  double get _displayExtension => isIncTax ? item.extension : item.extension / (1 + taxRate);

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
                      errorBuilder: (context, error, stackTrace) => Image.asset(
                        overviewPlaceholder,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Image.asset(
                      overviewPlaceholder,
                      fit: BoxFit.cover,
                    ),
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
                    fontWeight: FontWeight.w600,
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
                  "x${item.qty}",
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

  const TabletCartTile({
    super.key,
    required this.item,
    required this.index,
    required this.colors,
    required this.isDark,
    this.onDelete,
    this.isIncTax = true,
    this.taxRate = 0.1,
  });

  double get _displayPrice => isIncTax ? item.sellPrice : item.sellPrice / (1 + taxRate);
  double get _displayExtension => isIncTax ? item.extension : item.extension / (1 + taxRate);

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
                      errorBuilder: (context, error, stackTrace) => Image.asset(
                        overviewPlaceholder,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Image.asset(
                      overviewPlaceholder,
                      fit: BoxFit.cover,
                    ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              item.code,
              style: const TextStyle(
                fontFamily: 'monospace',
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
            width: 100,
            child: Text(
              "\$${_displayPrice.toStringAsFixed(2)}",
              textAlign: TextAlign.right,
              style: TextStyle(color: colors.onSurfaceMuted, fontSize: 13),
            ),
          ),
          SizedBox(
            width: 80,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? colors.surface : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  "x${item.qty}",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white70 : Colors.blueGrey.shade700,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 100,
            child: Text(
              "\$${_displayExtension.toStringAsFixed(2)}",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
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

  double get _displayExtension => isIncTax ? item.extension : item.extension / (1 + taxRate);

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.shortestSide >= 600;
    
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
                width: isTablet ? 50 : 30,
                child: Text(
                  "${item.qty}",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isTablet ? 14 : 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : Colors.blueGrey.shade700,
                  ),
                ),
              ),
              // Price
              SizedBox(
                width: isTablet ? 90 : 65,
                child: Text(
                  "\$${_displayExtension.toStringAsFixed(2)}",
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: isTablet ? 14 : 12,
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
        // Space for thumbnail
        const SizedBox(width: 57),
        Expanded(flex: 2, child: _buildHeader("Code")),
        Expanded(flex: 4, child: _buildHeader("Description")),
        SizedBox(width: 100, child: _buildHeader("Price", alignRight: true)),
        SizedBox(width: 80, child: Center(child: _buildHeader("Qty"))),
        SizedBox(width: 100, child: _buildHeader("Ext", alignRight: true)),
      ],
    );
  }

  Widget _buildHeader(String title, {bool alignRight = false}) {
    return Text(
      title,
      textAlign: alignRight ? TextAlign.right : TextAlign.left,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: colors.onSurfaceMuted,
      ),
    );
  }
}
