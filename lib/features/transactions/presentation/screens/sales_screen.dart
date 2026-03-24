import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import '../../../../constants/colors.dart';
import '../../../../constants/theme_colors.dart';
import '../../../../utils/navigation_extension.dart';
import '../../domain/models/cart_item.dart';
import '../widgets/sales/sales_widgets.dart';
import 'delivery_details_screen.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({
    super.key,
    this.title = "Sales",
    this.themeColor = Colors.green,
    this.icon = Icons.point_of_sale_outlined,
  });

  final String title;
  final Color themeColor;
  final IconData icon;

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _discountController = TextEditingController(text: "0.00");

  final bool _isPaymentMode = false;
  bool _showScanner = false;
  bool _showActions = false;
  bool _isIncTax = true;
  bool _isCompactView = false;
  bool _showTaxDetails = false;
  bool _showProfitDetails = false;
  String _selectedPaymentMethod = "Cash";
  String? _selectedOption;
  double _discountValue = 0.00;
  
  // Payment amounts for each payment type
  final Map<String, double> _paymentAmounts = {};
  
  // Survey and Comment values
  String _surveyValue = '';
  String _commentValue = '';
  final TextEditingController _surveyController = TextEditingController();

  late AnimationController _actionsAnimationController;
  late Animation<double> _actionsAnimation;

  final List<String> _optionItems = [
    "Add Survey",
    "Add Comment",
    "Add Delivery",
    "View Tax",
    "View Profit",
  ];

  final List<String> _paymentMethods = [
    "Cash",
    "EFTPOS",
    "Cheque",
    "Bank Card",
    "Master Card",
    "Visa",
    "Amex",
    "Diners",
    "Deposit",
  ];

  // Dummy data to populate the UI
  final List<CartItem> _cartItems = [
    CartItem(
      code: "AAA LYNN T",
      description: "AAA Lynn T-Shirt Large",
      sellPrice: 25.00,
      qty: 2,
    ),
    CartItem(
      code: "COF-PERC",
      description: "Coffee Percolator Pro",
      sellPrice: 120.00,
      qty: 1,
    ),
    CartItem(
      code: "SAUCE-NS",
      description: "Saucepan Set - Non Stick",
      sellPrice: 85.50,
      qty: 1,
    ),
    CartItem(
      code: "LAMP-LED",
      description: "LED Desk Lamp Adjustable",
      sellPrice: 45.99,
      qty: 1,
    ),
    CartItem(
      code: "HDPH-BT5",
      description: "Bluetooth Headphones Pro",
      sellPrice: 89.00,
      qty: 1,
    ),
    CartItem(
      code: "WATER-BTL",
      description: "Stainless Steel Water Bottle 1L",
      sellPrice: 18.50,
      qty: 3,
    ),
  ];

  double get _subtotal =>
      _cartItems.fold(0, (sum, item) => sum + item.extension);
  double get _discount => _discountValue;
  double get _rounding => 0.00; // Placeholder
  double get _total => _subtotal - _discount + _rounding;
  double get _totalPaid => _paymentAmounts.values.fold(0.0, (sum, amount) => sum + amount);

  @override
  void initState() {
    super.initState();
    _actionsAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _actionsAnimation = CurvedAnimation(
      parent: _actionsAnimationController,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _discountController.dispose();
    _actionsAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final bool isDark = colors.isDark;
    final bool isTablet = MediaQuery.of(context).size.shortestSide >= 600;

    return Scaffold(
      backgroundColor: isDark ? colors.bg : kBgColor,
      appBar: _buildAppBar(colors, isDark),
      body: SafeArea(
        child: Column(
          children: [
            // Top Section: Customer, Staff, Date
            _buildTopHeader(colors, isDark, isTablet),

            // Scanner Area (shown when scanner icon tapped)
            if (_showScanner) _buildScannerArea(colors, isDark),

            // Middle Section: Cart Items
            Expanded(child: _buildCartArea(colors, isDark, isTablet)),

            // Search Bar (moved to bottom)
            _buildSearchBar(colors, isDark, isTablet),

            // Bottom Section: Summary, Payment & Commit
            _buildBottomSummary(colors, isDark, isTablet),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(AppThemeColors colors, bool isDark) {
    return AppBar(
      elevation: 0,
      backgroundColor: widget.themeColor,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new,
          size: 20,
          color: Colors.white,
        ),
        onPressed: () => context.navigateBack(),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(widget.icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          Text(
            widget.title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 17,
            ),
          ),
        ],
      ),
      actions: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onSelected: (value) {
            if (value == 'default') {
              setState(() => _isCompactView = false);
            } else if (value == 'compact') {
              setState(() => _isCompactView = true);
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'default',
              child: Row(
                children: [
                  Icon(
                    _isCompactView ? Icons.radio_button_off : Icons.radio_button_checked,
                    size: 18,
                    color: _isCompactView ? Colors.grey : kPrimaryColor,
                  ),
                  const SizedBox(width: 8),
                  const Text('Default View'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'compact',
              child: Row(
                children: [
                  Icon(
                    _isCompactView ? Icons.radio_button_checked : Icons.radio_button_off,
                    size: 18,
                    color: _isCompactView ? kPrimaryColor : Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  const Text('Compact View'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTopHeader(AppThemeColors colors, bool isDark, bool isTablet) {
    // Dummy customer data - replace with actual
    const String customerBarcode = "CUST001";
    const String customerName = "Walk-in Customer";

    return Container(
      padding: EdgeInsets.fromLTRB(16, isTablet ? 12 : 8, 16, isTablet ? 12 : 8),
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
          // Info Row (Staff, Tax Toggle)
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
                    "Staff: David Bates",
                    style: TextStyle(
                      fontSize: isTablet ? 15 : 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : Colors.blueGrey.shade700,
                    ),
                  ),
                ],
              ),
              // Ex Tax / Inc Tax Toggle
              Container(
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
                      onTap: () => setState(() => _isIncTax = false),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: isTablet ? 16 : 10),
                        decoration: BoxDecoration(
                          color: !_isIncTax
                              ? kPrimaryColor
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(isTablet ? 17 : 12),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          "Ex Tax",
                          style: TextStyle(
                            fontSize: isTablet ? 13 : 10,
                            fontWeight: FontWeight.w800,
                            color: !_isIncTax
                                ? Colors.white
                                : colors.onSurfaceMuted,
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _isIncTax = true),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: isTablet ? 16 : 10),
                        decoration: BoxDecoration(
                          color: _isIncTax
                              ? kPrimaryColor
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(isTablet ? 17 : 12),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          "Inc Tax",
                          style: TextStyle(
                            fontSize: isTablet ? 13 : 10,
                            fontWeight: FontWeight.w800,
                            color: _isIncTax
                                ? Colors.white
                                : colors.onSurfaceMuted,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: isTablet ? 12 : 8),

          // Customer Selection Button
          InkWell(
            onTap: () {
              // Navigate to Customer Lookup to select a customer
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 14 : 10, 
                vertical: isTablet ? 12 : 8,
              ),
              decoration: BoxDecoration(
                color: isDark ? colors.surface : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark ? Colors.white12 : Colors.grey.shade300,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.person_outline, size: isTablet ? 22 : 18, color: kPrimaryColor),
                  SizedBox(width: isTablet ? 12 : 8),
                  Expanded(
                    child: Text(
                      "$customerBarcode | $customerName",
                      style: TextStyle(
                        fontSize: isTablet ? 15 : 13,
                        color: isDark ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Icon(Icons.search, size: isTablet ? 20 : 16, color: colors.onSurfaceMuted),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(AppThemeColors colors, bool isDark, bool isTablet) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Container(
        height: isTablet ? 50 : 44,
        decoration: BoxDecoration(
          color: isDark ? colors.surface : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDark ? Colors.white24 : kPrimaryColor.withOpacity(0.5),
          ),
        ),
        child: TextField(
          controller: _searchController,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontSize: 14,
          ),
          decoration: InputDecoration(
            hintText: 'Scan barcode or type to search (F2)',
            hintStyle: TextStyle(color: colors.onSurfaceMuted, fontSize: 13),
            suffixIcon: GestureDetector(
              onTap: () => setState(() => _showScanner = !_showScanner),
              child: Icon(
                Icons.qr_code_scanner,
                color: _showScanner ? Colors.green : kPrimaryColor,
                size: 20,
              ),
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
          onSubmitted: (value) {
            // Trigger Add to Cart logic
            _searchController.clear();
          },
        ),
      ),
    );
  }

  Widget _buildScannerArea(AppThemeColors colors, bool isDark) {
    final scannerHeight = MediaQuery.of(context).size.height * 0.18;
    return Container(
      height: scannerHeight,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? colors.surface : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white24 : Colors.grey.shade400,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: kThirdColor.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.qr_code_scanner,
              size: 55,
              color: kPrimaryColor.withOpacity(0.5),
            ),
            const SizedBox(height: 8),
            Text(
              "Scanner Area",
              style: TextStyle(color: colors.onSurfaceMuted, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              "Camera preview will appear here",
              style: TextStyle(
                color: colors.onSurfaceMuted.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartArea(AppThemeColors colors, bool isDark, bool isTablet) {
    if (_cartItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 60,
              color: colors.onSurfaceMuted.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              "Cart is empty",
              style: TextStyle(
                fontSize: 16,
                color: colors.onSurfaceMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Scan an item to begin.",
              style: TextStyle(
                fontSize: 13,
                color: colors.onSurfaceMuted.withOpacity(0.7),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Optional Tablet Header Row mimicking the desktop grid (not shown in compact view)
        if (isTablet && !_isCompactView)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? colors.surface : Colors.grey.shade200,
              border: Border(
                bottom: BorderSide(
                  color: isDark ? Colors.white12 : Colors.grey.shade300,
                ),
              ),
            ),
            child: Row(
              children: [
                // Space for thumbnail
                const SizedBox(width: 57),
                Expanded(flex: 2, child: _buildGridHeader("Code", colors)),
                Expanded(
                  flex: 4,
                  child: _buildGridHeader("Description", colors),
                ),
                SizedBox(
                  width: 100,
                  child: _buildGridHeader("Price", colors, alignRight: true),
                ),
                SizedBox(
                  width: 80,
                  child: Center(child: _buildGridHeader("Qty", colors)),
                ),
                SizedBox(
                  width: 100,
                  child: _buildGridHeader("Ext", colors, alignRight: true),
                ),
              ],
            ),
          ),

        // Cart List
        Expanded(
          child: AnimationLimiter(
            child: ListView.separated(
              controller: _scrollController,
              padding: EdgeInsets.symmetric(
                horizontal: 10,
                vertical: _isCompactView ? 2 : 6,
              ),
              itemCount: _cartItems.length,
              separatorBuilder: (context, index) => 
                  SizedBox(height: _isCompactView ? 0 : 4),
              itemBuilder: (context, index) {
                final item = _cartItems[index];
                return AnimationConfiguration.staggeredList(
                  position: index,
                  duration: const Duration(milliseconds: 300),
                  child: SlideAnimation(
                    verticalOffset: 20.0,
                    child: FadeInAnimation(
                      child: _isCompactView
                          ? _buildCompactCartTile(item, index, colors, isDark)
                          : isTablet
                              ? _buildTabletCartTile(item, index, colors, isDark)
                              : _buildMobileCartTile(item, index, colors, isDark),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGridHeader(
    String title,
    AppThemeColors colors, {
    bool alignRight = false,
  }) {
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

  Widget _buildMobileCartTile(
    CartItem item,
    int index,
    AppThemeColors colors,
    bool isDark,
  ) {
    return MobileCartTile(
      item: item,
      index: index,
      colors: colors,
      isDark: isDark,
    );
  }

  Widget _buildTabletCartTile(
    CartItem item,
    int index,
    AppThemeColors colors,
    bool isDark,
  ) {
    return TabletCartTile(
      item: item,
      index: index,
      colors: colors,
      isDark: isDark,
      onDelete: () => setState(() => _cartItems.removeAt(index)),
    );
  }

  Widget _buildCompactCartTile(
    CartItem item,
    int index,
    AppThemeColors colors,
    bool isDark,
  ) {
    return CompactCartTile(
      item: item,
      index: index,
      colors: colors,
      isDark: isDark,
    );
  }

  Widget _buildBottomSummary(
    AppThemeColors colors,
    bool isDark,
    bool isTablet,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2733) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Payment Methods Chips (only visible on Sales Screen)
              if (widget.title == "Sales") ...[
                SizedBox(
                  height: 34,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _paymentMethods.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 6),
                    itemBuilder: (context, index) {
                      final item = _paymentMethods[index];
                      final isSelected = _selectedPaymentMethod == item;
                      final hasAmount = _paymentAmounts.containsKey(item) && _paymentAmounts[item]! > 0;
                      final amount = _paymentAmounts[item] ?? 0;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedPaymentMethod = item;
                          });
                          _showPaymentAmountDialog(context, item, colors, isDark);
                        },
                        onLongPress: hasAmount ? () {
                          setState(() {
                            _paymentAmounts.remove(item);
                          });
                        } : null,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: hasAmount
                                ? kPrimaryColor
                                : (isSelected
                                    ? kPrimaryColor.withOpacity(0.3)
                                    : (isDark
                                          ? colors.surface
                                          : Colors.grey.shade100)),
                            borderRadius: BorderRadius.circular(17),
                            border: Border.all(
                              color: hasAmount || isSelected
                                  ? kPrimaryColor
                                  : (isDark
                                        ? Colors.white24
                                        : Colors.grey.shade300),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                item,
                                style: TextStyle(
                                  color: hasAmount
                                      ? Colors.white
                                      : (isSelected
                                          ? kPrimaryColor
                                          : (isDark
                                                ? Colors.white70
                                                : Colors.blueGrey.shade700)),
                                  fontWeight: hasAmount || isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  fontSize: 12,
                                ),
                              ),
                              if (hasAmount) ...[
                                const SizedBox(width: 4),
                                Text(
                                  "\$${amount.toStringAsFixed(0)}",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 10),
              ],

              // Totals Row
              IntrinsicHeight(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Actions Button and Profit breakdown (left column)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Profit breakdown display (above Actions button)
                        if (_showProfitDetails) ...[                          
                          _buildProfitBreakdown(colors, isDark),
                          const SizedBox(height: 8),
                        ],
                        // Actions Button
                        _buildActionsButton(colors, isDark, isTablet),
                      ],
                    ),

                    // Change/Remain amount display and Tax breakdown
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Change/Remain display
                          if (_totalPaid > _total)
                            Text(
                              "Change: \$${(_totalPaid - _total).toStringAsFixed(2)}",
                              style: const TextStyle(
                                color: Color(0xFF30B24C),
                                fontWeight: FontWeight.bold,
                                fontSize: 12.5,
                              ),
                            )
                          else if (_totalPaid > 0 && _totalPaid < _total)
                            Text(
                              "Remain: \$${(_total - _totalPaid).toStringAsFixed(2)}",
                              style: const TextStyle(
                                color: Colors.redAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 12.5,
                              ),
                            ),
                          
                          // Tax breakdown display
                          if (_showTaxDetails) ...[
                            const SizedBox(height: 6),
                            _buildTaxBreakdown(colors, isDark),
                          ],
                        ],
                      ),
                    ),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "Subtotal: \$${_subtotal.toStringAsFixed(2)}",
                          style: TextStyle(
                            color: colors.onSurfaceMuted,
                            fontSize: isTablet ? 14 : 12.5,
                          ),
                        ),
                        SizedBox(height: isTablet ? 12 : 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment:
                              isTablet ? CrossAxisAlignment.baseline : CrossAxisAlignment.center,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              "Discount: \$",
                              style: TextStyle(
                                color: colors.onSurfaceMuted,
                                fontSize: isTablet ? 14 : 12.5,
                              ),
                            ),
                            SizedBox(
                              width: isTablet ? 120 : 55,
                              height: isTablet ? 56 : 20,
                              child: isTablet
                                  ? MediaQuery(
                                      data: MediaQuery.of(context).copyWith(
                                        textScaler: TextScaler.noScaling,
                                      ),
                                      child: TextField(
                                        controller: _discountController,
                                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                        maxLines: 1,
                                        minLines: 1,
                                        textAlignVertical: TextAlignVertical.center,
                                        textAlign: TextAlign.right,
                                        style: TextStyle(
                                          color: isDark ? Colors.white : Colors.black87,
                                          fontSize: 18,
                                        ),
                                        decoration: InputDecoration(
                                          isDense: true,
                                          hintText: "0.00",
                                          hintStyle: TextStyle(
                                            color: colors.onSurfaceMuted,
                                            fontSize: 18,
                                          ),
                                          contentPadding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 0,
                                          ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(4),
                                            borderSide: BorderSide(
                                              color: isDark ? Colors.white24 : Colors.grey.shade300,
                                            ),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(4),
                                            borderSide: BorderSide(
                                              color: isDark ? Colors.white24 : Colors.grey.shade300,
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(4),
                                            borderSide: BorderSide(
                                              color: kPrimaryColor,
                                            ),
                                          ),
                                        ),
                                        onChanged: (value) {
                                          setState(() {
                                            _discountValue = double.tryParse(value) ?? 0.00;
                                          });
                                        },
                                      ),
                                    )
                                  : TextField(
                                      controller: _discountController,
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      maxLines: 1,
                                      minLines: 1,
                                      textAlign: TextAlign.right,
                                      style: TextStyle(
                                        color: isDark ? Colors.white : Colors.black87,
                                        fontSize: 12.5,
                                      ),
                                      decoration: InputDecoration(
                                        isDense: true,
                                        contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                          vertical: 2,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(4),
                                          borderSide: BorderSide(
                                            color: isDark ? Colors.white24 : Colors.grey.shade300,
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(4),
                                          borderSide: BorderSide(
                                            color: isDark ? Colors.white24 : Colors.grey.shade300,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(4),
                                          borderSide: BorderSide(
                                            color: kPrimaryColor,
                                          ),
                                        ),
                                      ),
                                      onChanged: (value) {
                                        setState(() {
                                          _discountValue = double.tryParse(value) ?? 0.00;
                                        });
                                      },
                                    ),
                            ),
                          ],
                        ),
                        SizedBox(height: isTablet ? 0 : 6),
                        Text(
                          "Rounding: \$${_rounding.toStringAsFixed(2)}",
                          style: TextStyle(
                            color: colors.onSurfaceMuted,
                            fontSize: isTablet ? 14 : 12.5,
                          ),
                        ),
                        SizedBox(height: isTablet ? 4 : 2),
                        Text(
                          "\$${_total.toStringAsFixed(2)}",
                          style: TextStyle(
                            fontSize: isTablet ? 32 : 26,
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white : Colors.black87,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPaymentAmountDialog(
    BuildContext context,
    String paymentMethod,
    AppThemeColors colors,
    bool isDark,
  ) {
    final existingAmount = _paymentAmounts[paymentMethod] ?? 0.0;
    final controller = TextEditingController(
      text: existingAmount > 0 ? existingAmount.toStringAsFixed(2) : '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (dialogContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(dialogContext).viewInsets.bottom,
          ),
          child: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E2733) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.4 : 0.15),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
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
                      "$paymentMethod Amount",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    if (existingAmount > 0)
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _paymentAmounts.remove(paymentMethod);
                          });
                          Navigator.of(dialogContext).pop();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            "Remove",
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller,
                        autofocus: true,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        decoration: InputDecoration(
                          prefixText: "\$ ",
                          prefixStyle: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                          hintText: "0.00",
                          hintStyle: TextStyle(
                            color: isDark ? Colors.white30 : Colors.grey.shade400,
                          ),
                          filled: true,
                          fillColor: isDark ? colors.surface : Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 14,
                          ),
                        ),
                        onSubmitted: (value) {
                          final amount = double.tryParse(value) ?? 0.0;
                          if (amount > 0) {
                            setState(() {
                              _paymentAmounts[paymentMethod] = amount;
                            });
                          } else {
                            setState(() {
                              _paymentAmounts.remove(paymentMethod);
                            });
                          }
                          Navigator.of(dialogContext).pop();
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () {
                        final amount = double.tryParse(controller.text) ?? 0.0;
                        if (amount > 0) {
                          setState(() {
                            _paymentAmounts[paymentMethod] = amount;
                          });
                        } else {
                          setState(() {
                            _paymentAmounts.remove(paymentMethod);
                          });
                        }
                        Navigator.of(dialogContext).pop();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF30B24C), Color(0xFF60D394)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSurveyMenuItem(
    BuildContext context,
    AppThemeColors colors,
    bool isDark,
    bool expanded,
    Function(bool) onExpandChanged,
  ) {
    final isTablet = MediaQuery.of(context).size.shortestSide >= 600;
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 16 : 12,
        vertical: isTablet ? 14 : 10,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2733) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: expanded
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () {
                    onExpandChanged(false);
                  },
                  child: Row(
                    children: [
                      Icon(
                        Icons.poll_outlined,
                        size: isTablet ? 22 : 18,
                        color: kPrimaryColor,
                      ),
                      SizedBox(width: isTablet ? 16 : 12),
                      Text(
                        "Add Survey",
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.blueGrey.shade800,
                          fontWeight: FontWeight.w500,
                          fontSize: isTablet ? 15 : 13,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: isTablet ? 12 : 8),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: isTablet ? 42 : 32,
                        child: TextField(
                          controller: _surveyController,
                          autofocus: true,
                          style: TextStyle(
                            fontSize: isTablet ? 14 : 12,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          decoration: InputDecoration(
                            hintText: "Survey code...",
                            hintStyle: TextStyle(
                              color: isDark ? Colors.white30 : Colors.grey.shade400,
                              fontSize: isTablet ? 14 : 12,
                            ),
                            filled: true,
                            fillColor: isDark ? colors.surface : Colors.grey.shade100,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: isTablet ? 14 : 10,
                              vertical: isTablet ? 12 : 8,
                            ),
                          ),
                          onSubmitted: (value) {
                            setState(() {
                              _surveyValue = value.trim();
                            });
                            onExpandChanged(false);
                          },
                        ),
                      ),
                    ),
                    SizedBox(width: isTablet ? 12 : 8),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _surveyValue = _surveyController.text.trim();
                        });
                        onExpandChanged(false);
                      },
                      child: Container(
                        padding: EdgeInsets.all(isTablet ? 10 : 6),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF30B24C), Color(0xFF60D394)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          Icons.check,
                          color: Colors.white,
                          size: isTablet ? 20 : 16,
                        ),
                      ),
                    ),
                    if (_surveyValue.isNotEmpty) ...[
                      SizedBox(width: isTablet ? 8 : 4),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _surveyValue = '';
                            _surveyController.clear();
                          });
                          onExpandChanged(false);
                        },
                        child: Container(
                          padding: EdgeInsets.all(isTablet ? 10 : 6),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            Icons.close,
                            color: Colors.redAccent,
                            size: isTablet ? 20 : 16,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            )
          : GestureDetector(
              onTap: () {
                onExpandChanged(true);
              },
              child: Row(
                children: [
                  Icon(
                    Icons.poll_outlined,
                    size: isTablet ? 22 : 18,
                    color: kPrimaryColor,
                  ),
                  SizedBox(width: isTablet ? 16 : 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Add Survey",
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.blueGrey.shade800,
                            fontWeight: FontWeight.w500,
                            fontSize: isTablet ? 15 : 13,
                          ),
                        ),
                        if (_surveyValue.isNotEmpty) ...[
                          SizedBox(height: isTablet ? 4 : 2),
                          Text(
                            _surveyValue,
                            style: TextStyle(
                              color: kPrimaryColor,
                              fontWeight: FontWeight.w600,
                              fontSize: isTablet ? 13 : 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  void _showCommentDialog(
    BuildContext context,
    AppThemeColors colors,
    bool isDark,
  ) {
    final controller = TextEditingController(text: _commentValue);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (dialogContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(dialogContext).viewInsets.bottom,
          ),
          child: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E2733) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.4 : 0.15),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
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
                      "Add Comment",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    if (_commentValue.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _commentValue = '';
                          });
                          Navigator.of(dialogContext).pop();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            "Remove",
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  autofocus: true,
                  maxLines: 4,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  decoration: InputDecoration(
                    hintText: "Enter comment...",
                    hintStyle: TextStyle(
                      color: isDark ? Colors.white30 : Colors.grey.shade400,
                    ),
                    filled: true,
                    fillColor: isDark ? colors.surface : Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _commentValue = controller.text.trim();
                      });
                      Navigator.of(dialogContext).pop();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF30B24C), Color(0xFF60D394)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        "Save",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showActionsMenu(
    BuildContext context,
    AppThemeColors colors,
    bool isDark,
  ) {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay =
        Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;
    final buttonPosition = button.localToGlobal(Offset.zero, ancestor: overlay);
    
    bool surveyExpanded = false;
    _surveyController.text = _surveyValue;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Actions Menu",
      barrierColor: Colors.black12,
      transitionDuration: const Duration(milliseconds: 550),
      pageBuilder: (context, animation, secondaryAnimation) {
        return const SizedBox.shrink();
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInQuart,
        );

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Stack(
              children: [
                Positioned(
                  left: 12,
                  bottom:
                      MediaQuery.of(context).size.height - buttonPosition.dy + 8,
                  child: Material(
                    color: Colors.transparent,
                    child: SizedBox(
                      width: MediaQuery.of(context).size.shortestSide >= 600 ? 280 : 220,
                      child: AnimatedBuilder(
                          animation: curvedAnimation,
                          builder: (context, child) {
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                ..._optionItems.reversed.toList().asMap().entries.map((entry) {
                                final reverseIndex = entry.key;
                                final index = _optionItems.length - 1 - reverseIndex;
                                final item = entry.value;
                                final isFirst = index == 0;
                                
                                // Stagger the reveal: bottom items appear first, slower rollout
                                final staggerFactor = _optionItems.length + 3;
                                final itemProgress = ((curvedAnimation.value * staggerFactor) - reverseIndex).clamp(0.0, 1.0);

                            return ClipRect(
                              child: Align(
                                alignment: Alignment.bottomCenter,
                                heightFactor: itemProgress,
                                child: Opacity(
                                  opacity: itemProgress,
                                  child: Padding(
                                    padding: EdgeInsets.only(
                                      left: 0,
                                      right: 40,
                                      top: isFirst ? 8 : 4,
                                      bottom: index == _optionItems.length - 1 ? 8 : 4,
                                    ),
                                    child: item == "Add Survey"
                                        ? _buildSurveyMenuItem(
                                            context,
                                            colors,
                                            isDark,
                                            surveyExpanded,
                                            (expanded) {
                                              setDialogState(() {
                                                surveyExpanded = expanded;
                                              });
                                            },
                                          )
                                        : InkWell(
                                      onTap: () {
                                        if (item == "Add Comment") {
                                          Navigator.of(context).pop();
                                          // Use a microtask to show dialog after pop completes
                                          Future.microtask(() {
                                            if (mounted) {
                                              _showCommentDialog(this.context, colors, isDark);
                                            }
                                          });
                                        } else if (item == "Add Delivery") {
                                          Navigator.of(context).pop();
                                          setState(() {
                                            _showActions = false;
                                            _actionsAnimationController.reverse();
                                          });
                                          // Navigate to Delivery Details screen
                                          Future.microtask(() {
                                            if (mounted) {
                                              Navigator.of(this.context).push(
                                                MaterialPageRoute(
                                                  builder: (context) => const DeliveryDetailsScreen(),
                                                ),
                                              );
                                            }
                                          });
                                        } else if (item == "View Tax") {
                                          Navigator.of(context).pop();
                                          setState(() {
                                            _showTaxDetails = !_showTaxDetails;
                                            _showActions = false;
                                            _actionsAnimationController.reverse();
                                          });
                                        } else if (item == "View Profit") {
                                          Navigator.of(context).pop();
                                          setState(() {
                                            _showProfitDetails = !_showProfitDetails;
                                            _showActions = false;
                                            _actionsAnimationController.reverse();
                                          });
                                        } else {
                                          Navigator.of(context).pop();
                                          setState(() {
                                            _selectedOption = item;
                                            _showActions = false;
                                            _actionsAnimationController.reverse();
                                          });
                                        }
                                      },
                                      borderRadius: BorderRadius.circular(10),
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: MediaQuery.of(context).size.shortestSide >= 600 ? 16 : 12,
                                          vertical: MediaQuery.of(context).size.shortestSide >= 600 ? 14 : 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isDark ? const Color(0xFF1E2733) : Colors.white,
                                          borderRadius: BorderRadius.circular(10),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              _getActionIcon(item),
                                              size: MediaQuery.of(context).size.shortestSide >= 600 ? 22 : 18,
                                              color: kPrimaryColor,
                                            ),
                                            SizedBox(width: MediaQuery.of(context).size.shortestSide >= 600 ? 16 : 12),
                                            Expanded(
                                              child: Text(
                                                      item,
                                                      style: TextStyle(
                                                        color: isDark
                                                            ? Colors.white
                                                            : Colors.blueGrey.shade800,
                                                        fontWeight: FontWeight.w500,
                                                        fontSize: MediaQuery.of(context).size.shortestSide >= 600 ? 15 : 13,
                                                      ),
                                                    ),
                                            ),
                                            // Arrow icon for Comment when has value
                                            if (item == "Add Comment" && _commentValue.isNotEmpty)
                                              Icon(
                                                Icons.arrow_forward_ios,
                                                size: MediaQuery.of(context).size.shortestSide >= 600 ? 16 : 14,
                                                color: kPrimaryColor,
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList().reversed,
                          // Finalise button - appears at bottom, animated last
                          Builder(
                            builder: (context) {
                              final isTablet = MediaQuery.of(context).size.shortestSide >= 600;
                              final finaliseProgress = ((curvedAnimation.value * (_optionItems.length + 4)) - _optionItems.length).clamp(0.0, 1.0);
                              return ClipRect(
                                child: Align(
                                  alignment: Alignment.bottomCenter,
                                  heightFactor: finaliseProgress,
                                  child: Opacity(
                                    opacity: finaliseProgress,
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                        left: 0,
                                        right: 0,
                                        top: 4,
                                        bottom: 8,
                                      ),
                                      child: InkWell(
                                        onTap: () {
                                          Navigator.of(context).pop();
                                          setState(() {
                                            _selectedOption = "Finalise";
                                            _showActions = false;
                                            _actionsAnimationController.reverse();
                                          });
                                        },
                                        borderRadius: BorderRadius.circular(10),
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 20,
                                            vertical: isTablet ? 14 : 10,
                                          ),
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [Color(0xFF30B24C), Color(0xFF60D394)],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            borderRadius: BorderRadius.circular(12),
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(0xFF30B24C).withOpacity(0.4),
                                                blurRadius: 10,
                                                offset: const Offset(0, 3),
                                              ),
                                            ],
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              const Icon(
                                                Icons.check_circle_outline,
                                                size: 22,
                                                color: Colors.white,
                                              ),
                                              const SizedBox(width: 12),
                                              const Text(
                                                "Finalise",
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      );
                      },
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      );
      },
    ).then((_) {
      if (mounted) {
        setState(() {
          _showActions = false;
          _actionsAnimationController.reverse();
        });
      }
    });
  }

  Widget _buildActionsButton(
    AppThemeColors colors,
    bool isDark,
    bool isTablet,
  ) {
    return Builder(
      builder: (context) => GestureDetector(
        onTap: () {
          setState(() {
            _showActions = !_showActions;
            if (_showActions) {
              _actionsAnimationController.forward();
              _showActionsMenu(context, colors, isDark);
            } else {
              _actionsAnimationController.reverse();
            }
          });
        },
        child: Container(
          padding: EdgeInsets.symmetric(
            vertical: isTablet ? 10 : 8,
            horizontal: isTablet ? 16 : 14,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _showActions
                  ? [Colors.green.shade400, Colors.green.shade600]
                  : [Colors.green.shade500, Colors.green.shade700],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "ACTIONS",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isTablet ? 13 : 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(width: 6),
              AnimatedRotation(
                turns: _showActions ? 0.5 : 0,
                duration: const Duration(milliseconds: 300),
                child: Icon(
                  Icons.keyboard_arrow_up_rounded,
                  color: Colors.white,
                  size: isTablet ? 20 : 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getActionIcon(String action) {
    switch (action) {
      case "Add Survey":
        return Icons.poll_outlined;
      case "Add Comment":
        return Icons.comment_outlined;
      case "Add Delivery":
        return Icons.local_shipping_outlined;
      case "View Tax":
        return Icons.receipt_long_outlined;
      case "View Profit":
        return Icons.trending_up_outlined;
      case "Finalise":
        return Icons.check_circle_outline;
      default:
        return Icons.more_horiz;
    }
  }

  Widget _buildTaxBreakdown(AppThemeColors colors, bool isDark) {
    return TaxBreakdownWidget(
      total: _total,
      colors: colors,
      isDark: isDark,
    );
  }

  Widget _buildProfitBreakdown(AppThemeColors colors, bool isDark) {
    return ProfitBreakdownWidget(
      subtotal: _subtotal,
      discount: _discount,
      colors: colors,
      isDark: isDark,
    );
  }
}

