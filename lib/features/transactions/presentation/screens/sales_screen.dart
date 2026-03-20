import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:intl/intl.dart';

// IMPORTANT: Adjust these imports to match your project structure
import '../../../../constants/colors.dart';
import '../../../../constants/theme_colors.dart';

import '../../../../utils/navigation_extension.dart';

/// Dummy model for UI demonstration purposes.
/// Replace with your actual CartItemVO / StockVO
class DummyCartItem {
  final String code;
  final String description;
  int qty;
  final double sellPrice;

  DummyCartItem({
    required this.code,
    required this.description,
    this.qty = 1,
    required this.sellPrice,
  });

  double get extension => qty * sellPrice;
}

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String _selectedPaymentMethod = "Cash";
  final List<String> _paymentMethods = [
    "Cash",
    "Account",
    "EFTPOS",
    "Sales Order",
    "Quote",
    "Lay-by",
    "Cheque",
    "Bank Card",
    "Master Card",
    "Visa",
    "Amex",
    "Diners",
    "Deposit",
  ];

  // Dummy data to populate the UI
  final List<DummyCartItem> _cartItems = [
    DummyCartItem(
      code: "AAA LYNN T",
      description: "AAA Lynn T-Shirt Large",
      sellPrice: 25.00,
      qty: 2,
    ),
    DummyCartItem(
      code: "COF-PERC",
      description: "Coffee Percolator Pro",
      sellPrice: 120.00,
      qty: 1,
    ),
    DummyCartItem(
      code: "SAUCE-NS",
      description: "Saucepan Set - Non Stick",
      sellPrice: 85.50,
      qty: 1,
    ),
  ];

  double get _subtotal =>
      _cartItems.fold(0, (sum, item) => sum + item.extension);
  double get _discount => 0.00; // Placeholder
  double get _total => _subtotal - _discount;

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
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
            // Top Section: Customer, Staff, Date & Barcode Input
            _buildTopHeader(colors, isDark, isTablet),

            // Middle Section: Cart Items
            Expanded(child: _buildCartArea(colors, isDark, isTablet)),

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
      backgroundColor: isDark ? colors.surfaceAlt : Colors.white,
      centerTitle: true,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios_new,
          size: 20,
          color: isDark ? Colors.white : Colors.black87,
        ),
        onPressed: () => context.navigateBack(),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.point_of_sale_rounded,
              color: Colors.green,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            "New Transaction",
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 17,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(
            Icons.more_vert,
            color: isDark ? Colors.white : Colors.black87,
          ),
          onPressed: () {
            // Options menu (e.g., Clear Sale, Suspend Sale)
          },
        ),
      ],
    );
  }

  Widget _buildTopHeader(AppThemeColors colors, bool isDark, bool isTablet) {
    final String currentDate = DateFormat(
      'EEEE, dd MMM yyyy',
    ).format(DateTime.now());

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: isDark ? colors.surfaceAlt : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.white12 : Colors.grey.shade200,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Info Row (Staff, Date)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.badge_outlined,
                    size: 16,
                    color: colors.onSurfaceMuted,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "Staff: David Bates", // Replace with AppGlobals.instance.staffName
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : Colors.blueGrey.shade700,
                    ),
                  ),
                ],
              ),
              Text(
                currentDate,
                style: TextStyle(fontSize: 12, color: colors.onSurfaceMuted),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Customer Selection Button
          InkWell(
            onTap: () {
              // Navigate to Customer Lookup to select a customer
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? colors.surface : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark ? Colors.white12 : Colors.grey.shade300,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.person_outline, size: 20, color: kPrimaryColor),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Walk-in Customer", // Or selected customer name
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Icon(Icons.search, size: 18, color: colors.onSurfaceMuted),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Barcode / Product Search Input
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: isDark ? colors.surface : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark
                          ? Colors.white24
                          : kPrimaryColor.withOpacity(0.5),
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
                      hintStyle: TextStyle(
                        color: colors.onSurfaceMuted,
                        fontSize: 13,
                      ),
                      prefixIcon: const Icon(
                        Icons.qr_code_scanner,
                        color: kPrimaryColor,
                        size: 20,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onSubmitted: (value) {
                      // Trigger Add to Cart logic
                      _searchController.clear();
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
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
        // Optional Tablet Header Row mimicking the desktop grid
        if (isTablet)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
                  width: 120,
                  child: Center(child: _buildGridHeader("Qty", colors)),
                ),
                SizedBox(
                  width: 100,
                  child: _buildGridHeader("Ext", colors, alignRight: true),
                ),
                const SizedBox(width: 40), // Space for delete button
              ],
            ),
          ),

        // Cart List
        Expanded(
          child: AnimationLimiter(
            child: ListView.separated(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              itemCount: _cartItems.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = _cartItems[index];
                return AnimationConfiguration.staggeredList(
                  position: index,
                  duration: const Duration(milliseconds: 300),
                  child: SlideAnimation(
                    verticalOffset: 20.0,
                    child: FadeInAnimation(
                      child: isTablet
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
    DummyCartItem item,
    int index,
    AppThemeColors colors,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? colors.surfaceAlt : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  item.code,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: kPrimaryColor,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "\$${item.sellPrice.toStringAsFixed(2)}",
                  style: TextStyle(fontSize: 13, color: colors.onSurfaceMuted),
                ),
              ],
            ),
          ),

          // Quantity & Pricing Controls
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Extension Total
              Text(
                "\$${item.extension.toStringAsFixed(2)}",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 12),

              // Qty Stepper
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildQtyBtn(
                    Icons.remove,
                    () {
                      if (item.qty > 1) setState(() => item.qty--);
                    },
                    isDark,
                    colors,
                  ),
                  Container(
                    width: 36,
                    alignment: Alignment.center,
                    child: Text(
                      item.qty.toString(),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                  _buildQtyBtn(
                    Icons.add,
                    () {
                      setState(() => item.qty++);
                    },
                    isDark,
                    colors,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabletCartTile(
    DummyCartItem item,
    int index,
    AppThemeColors colors,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? colors.surfaceAlt : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
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
              "\$${item.sellPrice.toStringAsFixed(2)}",
              textAlign: TextAlign.right,
              style: TextStyle(color: colors.onSurfaceMuted, fontSize: 13),
            ),
          ),
          SizedBox(
            width: 120,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildQtyBtn(
                  Icons.remove,
                  () {
                    if (item.qty > 1) setState(() => item.qty--);
                  },
                  isDark,
                  colors,
                  small: true,
                ),
                Container(
                  width: 30,
                  alignment: Alignment.center,
                  child: Text(
                    item.qty.toString(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                _buildQtyBtn(
                  Icons.add,
                  () {
                    setState(() => item.qty++);
                  },
                  isDark,
                  colors,
                  small: true,
                ),
              ],
            ),
          ),
          SizedBox(
            width: 100,
            child: Text(
              "\$${item.extension.toStringAsFixed(2)}",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
          SizedBox(
            width: 40,
            child: IconButton(
              icon: const Icon(
                Icons.delete_outline,
                color: Colors.redAccent,
                size: 20,
              ),
              onPressed: () {
                setState(() => _cartItems.removeAt(index));
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQtyBtn(
    IconData icon,
    VoidCallback onTap,
    bool isDark,
    AppThemeColors colors, {
    bool small = false,
  }) {
    final size = small ? 26.0 : 32.0;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: isDark ? colors.surface : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isDark ? Colors.white24 : Colors.grey.shade300,
          ),
        ),
        child: Icon(
          icon,
          size: small ? 14 : 16,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
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
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Payment Methods
              SizedBox(
                height: 38,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _paymentMethods.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final method = _paymentMethods[index];
                    final isSelected = _selectedPaymentMethod == method;
                    return InkWell(
                      onTap: () =>
                          setState(() => _selectedPaymentMethod = method),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? kPrimaryColor
                              : (isDark
                                    ? colors.surface
                                    : Colors.grey.shade100),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? kPrimaryColor
                                : (isDark
                                      ? Colors.white24
                                      : Colors.grey.shade300),
                          ),
                        ),
                        child: Text(
                          method,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : (isDark
                                      ? Colors.white70
                                      : Colors.blueGrey.shade700),
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Totals Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Subtotal: \$${_subtotal.toStringAsFixed(2)}",
                        style: TextStyle(
                          color: colors.onSurfaceMuted,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Total to Pay",
                        style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.black54,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        "\$${_total.toStringAsFixed(2)}",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : Colors.black87,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),

                  // Commit Button (Mimics Desktop F10 Green Button)
                  SizedBox(
                    height: 54,
                    width: isTablet ? 200 : 150,
                    child: ElevatedButton(
                      onPressed: _cartItems.isEmpty
                          ? null
                          : () {
                              // Dispatch Commit Sale Event
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        disabledBackgroundColor: Colors.grey.shade400,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "COMMIT",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isTablet ? 16 : 14,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          if (isTablet) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black26,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                "F10",
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
