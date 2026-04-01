import 'package:flutter/material.dart';

import '../../../../constants/colors.dart';
import '../../../../constants/theme_colors.dart';
import '../../../../utils/responsive_utils.dart';
import '../screens/sales_screen.dart';

/// Top header widget for sales screen - displays staff, tax toggle, and customer selection
class SalesTopHeader extends StatefulWidget {
  final bool isIncTax;
  final ValueChanged<bool> onTaxModeChanged;
  final ValueChanged<String>? onCustomerSearch;
  final VoidCallback? onCustomerClear;
  final String? customerBarcode;
  final String? customerName;
  final String staffName;
  final bool hasCustomer;
  final bool autoFocusCustomer;
  final CartViewMode? viewMode;
  final ValueChanged<CartViewMode>? onViewModeChanged;
  final VoidCallback? onViewCustomerTransactions;

  const SalesTopHeader({
    super.key,
    required this.isIncTax,
    required this.onTaxModeChanged,
    required this.staffName,
    this.onCustomerSearch,
    this.onCustomerClear,
    this.onViewCustomerTransactions,
    this.customerBarcode,
    this.customerName,
    this.hasCustomer = false,
    this.autoFocusCustomer = false,
    this.viewMode,
    this.onViewModeChanged,
  });

  @override
  State<SalesTopHeader> createState() => _SalesTopHeaderState();
}

class _SalesTopHeaderState extends State<SalesTopHeader> {
  bool _isSearchMode = true; // Start in search mode
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Auto-focus customer field if requested
    if (widget.autoFocusCustomer) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _searchFocusNode.requestFocus();
      });
    }
  }

  @override
  void didUpdateWidget(covariant SalesTopHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    // When customer is selected, exit search mode to show customer info
    if (widget.hasCustomer && !oldWidget.hasCustomer) {
      setState(() => _isSearchMode = false);
    }
    // When customer is cleared, enter search mode
    if (!widget.hasCustomer && oldWidget.hasCustomer) {
      setState(() => _isSearchMode = true);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _enterSearchMode() {
    setState(() {
      _isSearchMode = true;
      _searchController.clear();
    });
    Future.delayed(const Duration(milliseconds: 50), () {
      _searchFocusNode.requestFocus();
    });
  }

  void _exitSearchMode() {
    // Only allow exiting search mode if a customer is selected
    if (widget.hasCustomer) {
      setState(() => _isSearchMode = false);
      _searchFocusNode.unfocus();
    }
  }

  void _submitSearch() {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      widget.onCustomerSearch?.call(query);
      _searchController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final bool isDark = colors.isDark;
    final bool isTablet = context.isTablet;

    return Container(
      padding: EdgeInsets.fromLTRB(12, isTablet ? 8 : 5, 12, isTablet ? 8 : 5),
      decoration: BoxDecoration(
        color: isDark ? colors.surfaceAlt : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.white12 : Colors.grey.shade200,
          ),
        ),
      ),
      child: Column(
        children: [
          // Info Row (Staff, View Mode Toggle, Tax Toggle)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.badge_outlined,
                    size: isTablet ? 18 : 14,
                    color: colors.onSurfaceMuted,
                  ),
                  SizedBox(width: isTablet ? 8 : 4),
                  Text(
                    "Staff: ${widget.staffName}",
                    style: TextStyle(
                      fontSize: isTablet ? 15 : 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : Colors.blueGrey.shade700,
                    ),
                  ),
                ],
              ),
              // View Mode Toggle (tablet only)
              if (isTablet && widget.viewMode != null && widget.onViewModeChanged != null)
                _buildViewModeToggle(colors, isDark, isTablet),
              // Ex Tax / Inc Tax Toggle
              _buildTaxToggle(colors, isDark, isTablet),
            ],
          ),
          SizedBox(height: isTablet ? 8 : 5),

          // Customer Search Field or Selected Customer Display
          _isSearchMode || !widget.hasCustomer
              ? _buildCustomerSearchField(colors, isDark, isTablet)
              : _buildCustomerSelector(colors, isDark, isTablet),
        ],
      ),
    );
  }

  Widget _buildTaxToggle(AppThemeColors colors, bool isDark, bool isTablet) {
    return Container(
      height: isTablet ? 34 : 24,
      decoration: BoxDecoration(
        color: isDark ? colors.surface : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(isTablet ? 17 : 12),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.grey.shade300,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => widget.onTaxModeChanged(false),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: isTablet ? 16 : 10),
              decoration: BoxDecoration(
                color: !widget.isIncTax ? kPrimaryColor : Colors.transparent,
                borderRadius: BorderRadius.circular(isTablet ? 17 : 12),
              ),
              alignment: Alignment.center,
              child: Text(
                "Ex Tax",
                style: TextStyle(
                  fontSize: isTablet ? 13 : 10,
                  fontWeight: FontWeight.w800,
                  color: !widget.isIncTax ? Colors.white : colors.onSurfaceMuted,
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: () => widget.onTaxModeChanged(true),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: isTablet ? 16 : 10),
              decoration: BoxDecoration(
                color: widget.isIncTax ? kPrimaryColor : Colors.transparent,
                borderRadius: BorderRadius.circular(isTablet ? 17 : 12),
              ),
              alignment: Alignment.center,
              child: Text(
                "Inc Tax",
                style: TextStyle(
                  fontSize: isTablet ? 13 : 10,
                  fontWeight: FontWeight.w800,
                  color: widget.isIncTax ? Colors.white : colors.onSurfaceMuted,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewModeToggle(AppThemeColors colors, bool isDark, bool isTablet) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      decoration: BoxDecoration(
        color: isDark ? colors.surface.withOpacity(0.8) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? Colors.white24 : Colors.grey.shade300,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: CartViewMode.values.map((mode) {
          final isSelected = widget.viewMode == mode;
          return GestureDetector(
            onTap: () {
              widget.onViewModeChanged?.call(mode);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? kPrimaryColor.withOpacity(0.2)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                mode.icon,
                size: isTablet ? 22 : 18,
                color: isSelected
                    ? kPrimaryColor
                    : (isDark ? Colors.white70 : Colors.blueGrey.shade600),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCustomerSearchField(AppThemeColors colors, bool isDark, bool isTablet) {
    return Container(
      height: isTablet ? 46 : 40,
      decoration: BoxDecoration(
        color: isDark ? colors.surface : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? Colors.white24 : kPrimaryColor.withOpacity(0.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white : Colors.black87,
              ),
              decoration: InputDecoration(
                hintText: "Search customer: barcode, name, phone, email...",
                hintStyle: TextStyle(
                  fontSize: 13,
                  color: colors.onSurfaceMuted,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(left: 12, right: 8),
                  child: Icon(
                    Icons.person_search_outlined,
                    size: 22,
                    color: kPrimaryColor,
                  ),
                ),
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 42,
                  minHeight: 22,
                ),
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _submitSearch(),
            ),
          ),
          // Close button (only show if customer is selected, allowing to cancel search)
          if (widget.hasCustomer)
            GestureDetector(
              onTap: _exitSearchMode,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Icon(
                  Icons.close,
                  size: 22,
                  color: colors.onSurfaceMuted,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCustomerSelector(AppThemeColors colors, bool isDark, bool isTablet) {
    return Container(
      height: isTablet ? 46 : 40,
      decoration: BoxDecoration(
        color: isDark ? colors.surface : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? Colors.white24 : kPrimaryColor.withOpacity(0.5),
        ),
      ),
      child: Row(
        children: [
          // Person icon
          Padding(
            padding: const EdgeInsets.only(left: 12, right: 8),
            child: Icon(
              Icons.person,
              size: 22,
              color: kPrimaryColor,
            ),
          ),
          // Customer info (display only - tap X to clear and add new customer)
          Expanded(
            child: Container(
              alignment: Alignment.centerLeft,
              child: Text(
                "${widget.customerBarcode ?? ''} | ${widget.customerName ?? ''}",
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          // View transactions button
          GestureDetector(
            onTap: widget.onViewCustomerTransactions,
            child: Padding(
              padding: EdgeInsets.only(left: 8, right: isTablet ? 0 : 4),
              child: Icon(
                Icons.receipt_long_outlined,
                size: isTablet ? 26 : 22,
                color: kPrimaryColor,
              ),
            ),
          ),
          // Clear button
          GestureDetector(
            onTap: widget.onCustomerClear,
            child: Padding(
              padding: EdgeInsets.only(left: isTablet ? 15 : 0, right: 12),
              child: Icon(
                Icons.close,
                size: isTablet ? 26 : 22,
                color: colors.onSurfaceMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
