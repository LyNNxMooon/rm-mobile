import 'package:flutter/material.dart';
import 'package:rmmobile/features/transactions/presentation/screens/sales_screen.dart';

import '../../../../constants/colors.dart';
import '../../../../constants/theme_colors.dart';
import '../../../../utils/responsive_utils.dart';

/// Top header widget for sales screen - displays staff, tax toggle, and customer selection
class SalesTopHeader extends StatefulWidget {
  final bool isIncTax;
  final ValueChanged<bool> onTaxModeChanged;
  final ValueChanged<String>? onCustomerSearch;
  final VoidCallback? onCustomerClear;
  final String? customerBarcode;
  final String? customerName;
  final int? customerGrade;
  final String staffName;
  final bool hasCustomer;
  final bool autoFocusCustomer;
  final CartViewMode? viewMode;
  final ValueChanged<CartViewMode>? onViewModeChanged;
  final VoidCallback? onViewCustomerTransactions;
  final VoidCallback? onCustomerFieldFocus;
  final VoidCallback? onGoToCustomerLookup;
  final VoidCallback? onCreateCustomer;
  final VoidCallback? onCustomerSearchEmpty;

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
    this.customerGrade,
    this.hasCustomer = false,
    this.autoFocusCustomer = false,
    this.viewMode,
    this.onViewModeChanged,
    this.onCustomerFieldFocus,
    this.onGoToCustomerLookup,
    this.onCreateCustomer,
    this.onCustomerSearchEmpty,
  });

  @override
  State<SalesTopHeader> createState() => _SalesTopHeaderState();
}

class _SalesTopHeaderState extends State<SalesTopHeader> {
  bool _isSearchMode = true; // Start in search mode
  bool _isSearchFocused = false; // Track focus state for border highlight
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Listen to focus changes on customer search field
    _searchFocusNode.addListener(_onSearchFocusChange);
    // Auto-focus customer field if requested
    if (widget.autoFocusCustomer) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _searchFocusNode.requestFocus();
      });
    }
  }

  void _onSearchFocusChange() {
    if (_searchFocusNode.hasFocus) {
      widget.onCustomerFieldFocus?.call();
    }
    // Update focus state for border highlight
    if (mounted) {
      setState(() => _isSearchFocused = _searchFocusNode.hasFocus);
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
    _searchFocusNode.removeListener(_onSearchFocusChange);
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
    } else {
      // User pressed Enter without typing - focus stock search
      widget.onCustomerSearchEmpty?.call();
    }
  }

  Widget _buildFieldIconButton({
    required bool isTablet,
    required bool isDark,
    required AppThemeColors colors,
    required IconData icon,
    required VoidCallback onTap,
    required Color iconColor,
    bool isMuted = false,
  }) {
    final double size = isTablet ? 40 : 36;
    final Color background =
        isDark ? Colors.black : kPrimaryColor.withOpacity(0.10);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: background,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: isTablet ? 22 : 20,
            color: iconColor,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final bool isDark = colors.isDark;
    final bool isTablet = context.isTablet;
    final bool useDesktopNav = context.useDesktopNav;

    return Container(
      padding: EdgeInsets.fromLTRB(12, isTablet ? 8 : 5, 12, isTablet ? 8 : 5),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF212121) : Colors.white,
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
              // View Mode Toggle (tablet and desktop)
              if ((isTablet || useDesktopNav) && widget.viewMode != null && widget.onViewModeChanged != null)
                _buildViewModeToggle(colors, isDark, isTablet || useDesktopNav),
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
        color: isDark ? Colors.black : Colors.grey.shade100,
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
        color: isDark ? Colors.black : Colors.grey.shade100,
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
    final bool useDesktopNav = context.useDesktopNav;
    final double containerHeight = useDesktopNav ? 36 : (isTablet ? 46 : 40);

    return Row(
      children: [
        Expanded(
          child: Container(
            height: containerHeight,
            decoration: BoxDecoration(
              color: isDark ? Colors.black : Colors.white,
              borderRadius: BorderRadius.circular(containerHeight / 2),
              border: Border.all(
                color: _isSearchFocused
                    ? kPrimaryColor
                    : (isDark ? Colors.white24 : kPrimaryColor.withOpacity(0.5)),
                width: _isSearchFocused ? 2 : 1,
              ),
            ),
            child: Center(
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                // Disable autocorrect and predictive text
                autocorrect: false,
                enableSuggestions: false,
                style: TextStyle(
                  fontSize: useDesktopNav ? 13 : 14,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                textAlignVertical: TextAlignVertical.center,
                decoration: InputDecoration(
                  hintText: "Search customer: barcode, name, phone, email...",
                  hintStyle: TextStyle(
                    fontSize: useDesktopNav ? 12 : 13,
                    color: colors.onSurfaceMuted,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: useDesktopNav ? 8 : 10,
                  ),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(left: 12, right: 8),
                    child: Icon(
                      Icons.person_search_outlined,
                      size: useDesktopNav ? 18 : 22,
                      color: kPrimaryColor,
                    ),
                  ),
                  prefixIconConstraints: BoxConstraints(
                    minWidth: useDesktopNav ? 38 : 42,
                    minHeight: useDesktopNav ? 18 : 22,
                  ),
                ),
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _submitSearch(),
              ),
            ),
          ),
        ),
        // Close button (only show if customer is selected, allowing to cancel search)
        if (widget.hasCustomer) ...[
          SizedBox(width: isTablet ? 10 : 8),
          _buildFieldIconButton(
            isTablet: isTablet,
            isDark: isDark,
            colors: colors,
            icon: Icons.close,
            onTap: _exitSearchMode,
            iconColor: colors.onSurfaceMuted,
            isMuted: true,
          ),
        ],
        // Go to Customer Lookup button (only show when no customer)
        if (!widget.hasCustomer && widget.onGoToCustomerLookup != null) ...[
          SizedBox(width: isTablet ? 10 : 8),
          _buildFieldIconButton(
            isTablet: isTablet,
            isDark: isDark,
            colors: colors,
            icon: Icons.double_arrow_rounded,
            onTap: widget.onGoToCustomerLookup!,
            iconColor: kPrimaryColor,
          ),
        ],
        if (!widget.hasCustomer && widget.onCreateCustomer != null) ...[
          SizedBox(width: isTablet ? 10 : 8),
          _buildFieldIconButton(
            isTablet: isTablet,
            isDark: isDark,
            colors: colors,
            icon: Icons.add_circle,
            onTap: widget.onCreateCustomer!,
            iconColor: kPrimaryColor,
          ),
        ],
      ],
    );
  }

  Widget _buildCustomerSelector(AppThemeColors colors, bool isDark, bool isTablet) {
    final bool useDesktopNav = context.useDesktopNav;
    final double containerHeight = useDesktopNav ? 36 : (isTablet ? 46 : 40);

    return Row(
      children: [
        Expanded(
          child: Container(
            height: containerHeight,
            decoration: BoxDecoration(
              color: isDark ? Colors.black : Colors.white,
              borderRadius: BorderRadius.circular(containerHeight / 2),
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
                    size: useDesktopNav ? 18 : 22,
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
                        fontSize: useDesktopNav ? 13 : 14,
                        color: isDark ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                // Customer grade badge
                if (widget.customerGrade != null)
                  Container(
                    margin: EdgeInsets.only(right: isTablet ? 8 : 6),
                    padding: EdgeInsets.symmetric(
                      horizontal: useDesktopNav ? 6 : (isTablet ? 10 : 8),
                      vertical: useDesktopNav ? 2 : (isTablet ? 4 : 3),
                    ),
                    decoration: BoxDecoration(
                      color: kPrimaryColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: kPrimaryColor.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "\$ ",
                          style: TextStyle(
                            fontSize: useDesktopNav ? 11 : (isTablet ? 14 : 12),
                            fontWeight: FontWeight.w900,
                            color: kPrimaryColor,
                          ),
                        ),
                        Text(
                          _gradeLabel(widget.customerGrade!),
                          style: TextStyle(
                            fontSize: useDesktopNav ? 10 : (isTablet ? 13 : 11),
                            fontWeight: FontWeight.w700,
                            color: kPrimaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        // View transactions button
        SizedBox(width: isTablet ? 10 : 8),
        _buildFieldIconButton(
          isTablet: isTablet,
          isDark: isDark,
          colors: colors,
          icon: Icons.receipt_long_outlined,
          onTap: widget.onViewCustomerTransactions ?? () {},
          iconColor: kPrimaryColor,
        ),
        // Clear button
        SizedBox(width: isTablet ? 10 : 8),
        _buildFieldIconButton(
          isTablet: isTablet,
          isDark: isDark,
          colors: colors,
          icon: Icons.close,
          onTap: widget.onCustomerClear ?? () {},
          iconColor: colors.onSurfaceMuted,
          isMuted: true,
        ),
      ],
    );
  }

  /// Returns display label for customer grade
  String _gradeLabel(int grade) {
    switch (grade) {
      case 0:
        return "Def";
      case 1:
        return "A";
      case 2:
        return "B";
      case 3:
        return "C";
      case 4:
        return "D";
      default:
        return "Def";
    }
  }
}
