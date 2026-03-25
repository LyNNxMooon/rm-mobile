import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:rmstock_scanner/utils/navigation_extension.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

import '../../../../constants/colors.dart';
import '../../../../constants/theme_colors.dart';
import '../../../../constants/txt_styles.dart';
import '../../../../utils/global_var_utils.dart';
import '../../../stock_lookup/presentation/screens/stock_lookup_screen.dart';
import '../../../customer_lookup/presentation/screens/customer_lookup_screen.dart';
import '../../../transactions/presentation/screens/sales_screen.dart';
import '../BLoC/home_screen_bloc.dart';
import '../BLoC/home_screen_states.dart';
import '../screens/coming_soon_screen.dart';

// IMPORTANT: Adjust this import to match your folder structure
import 'action_card.dart';

class GlassDrawer extends StatefulWidget {
  const GlassDrawer({
    super.key,
    this.initialChildSize,
    this.minChildSize,
    this.maxChildSize,
    required this.onStocktakeTap,
  });

  final double? initialChildSize;
  final double? minChildSize;
  final double? maxChildSize;
  final VoidCallback onStocktakeTap;

  @override
  State<GlassDrawer> createState() => _GlassDrawerState();
}

class _GlassDrawerState extends State<GlassDrawer> {
  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    final sheet = DraggableScrollableSheet(
      initialChildSize: widget.initialChildSize ?? 0.55,
      minChildSize: widget.minChildSize ?? 0.55,
      maxChildSize: widget.maxChildSize ?? 0.90,
      builder: (context, scrollController) {
        return ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(40),
            topRight: Radius.circular(40),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              decoration: BoxDecoration(
                color: colors.glassFill,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
                border: Border.all(color: colors.glassBorder),
                boxShadow: [
                  BoxShadow(blurRadius: 20, color: colors.cardShadow),
                ],
              ),
              child: Column(
                children: [
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 12),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colors.isDark
                            ? colors.onSurfaceMuted
                            : kSecondaryColor.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: BlocBuilder<StaffAuthBloc, StaffAuthStates>(
                      builder: (context, staffState) {
                        return BlocBuilder<ShopFrontConnectionBloc,
                            ShopfrontConnectionStates>(
                          builder: (context, state) {
                            final shop = AppGlobals.instance.shopfront;
                            final shopText = (shop == null || shop.isEmpty)
                                ? "Connect to a shopfront..."
                                : shop.split(r'\\').last;

                            return Text(
                              shopText,
                              style: TextStyle(
                                color: colors.isDark
                                    ? colors.onSurface
                                    : kSecondaryColor,
                                fontSize: 16,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            );
                          },
                        );
                      },
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.shortestSide >= 600 ? 15 : 14),
                  Expanded(child: dashBoardView(scrollController)),
                ],
              ),
            ),
          ),
        );
      },
    );

    return sheet;
  }

  Widget _buildSectionTitle(String title, BuildContext context) {
    final colors = context.appColors;
    final bool isTablet = MediaQuery.of(context).size.shortestSide >= 600;
    final double fontSize = isTablet ? 18 : 16;

    return Padding(
      padding: EdgeInsets.only(left: 28, right: 28, top: isTablet ? 10 : 8, bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: colors.isDark ? Colors.white : Colors.white,
        ),
      ),
    );
  }

  Widget dashBoardView(ScrollController scrollController) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final bool isTablet = MediaQuery.of(context).size.shortestSide >= 600;
        final bool isTabletPortrait =
            isTablet && MediaQuery.of(context).orientation == Orientation.portrait;
        final bool isLargeTablet =
            isTablet && MediaQuery.of(context).size.shortestSide >= 900;

        int crossAxisCount = 2;
        if (isTabletPortrait && isLargeTablet) {
          crossAxisCount = 2;
        } else if (width > 600 || isTabletPortrait) {
          crossAxisCount = 3;
        }
        if (width > 900 && !isTabletPortrait) crossAxisCount = 4;

        double spacing = width > 600 ? 20.0 : 15.0;
        final double targetHeight = isTabletPortrait
          ? (isLargeTablet ? 155.0 : 130.0)
          : (isLargeTablet ? 135.0 : (isTablet ? 105.0 : 85.0));
        final double availableWidth = width - 50 - (spacing * (crossAxisCount - 1));
        final double itemWidth = availableWidth / crossAxisCount;
        final double childAspectRatio = itemWidth / targetHeight;

        return ListView(
          controller: scrollController,
          padding: EdgeInsets.only(top: isTablet ? 10 : 8, bottom: 40),
          physics: const ClampingScrollPhysics(),
          children: [
            // --- SECTION 1: TRANSACTIONS ---
            _buildSectionTitle("Transactions", context),
            AnimationLimiter(
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 25),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: spacing,
                  mainAxisSpacing: spacing,
                  childAspectRatio: childAspectRatio,
                ),
                itemCount: _transactionItems.length,
                itemBuilder: (context, index) {
                  return _buildGridItem(
                    _transactionItems[index],
                    context,
                    index,
                    crossAxisCount,
                    isTransaction: true,
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            // --- SECTION 2: INFORMATION ---
            _buildSectionTitle("Information", context),
            AnimationLimiter(
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 25),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: spacing,
                  mainAxisSpacing: spacing,
                  childAspectRatio: childAspectRatio,
                ),
                itemCount: _infoItems.length,
                itemBuilder: (context, index) {
                  return _buildGridItem(
                    _infoItems[index],
                    context,
                    index,
                    crossAxisCount,
                    isTransaction: false,
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            // --- SECTION 3: MANAGEMENT ---
            _buildSectionTitle("Stock Management", context),
            ActionCard(
              title: "Stocktake",
              subtitle: "Begin counting inventory items",
              onTap: widget.onStocktakeTap,
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleNavigation(String action, BuildContext context) async {
    if (action == "stock_lookup") {
      if (!AppGlobals.instance.hasAnyPermission(const <String>["Information_Stock"])) {
        showTopSnackBar(
          Overlay.of(context),
          const CustomSnackBar.error(
            message: "You do not have permission to access Stock Lookup.",
          ),
        );
        return;
      }
      context.navigateToNext(const StockLookupScreen());
    } else if (action == "customer_lookup") {
      if (!AppGlobals.instance.hasAnyPermission(const <String>["Information_Customer"])) {
        showTopSnackBar(
          Overlay.of(context),
          const CustomSnackBar.error(
            message: "You do not have permission to access Customer Lookup.",
          ),
        );
        return;
      }
      context.navigateToNext(const CustomerLookupScreen());
    } else if (action == "sales") {
      context.navigateToNext(const SalesScreen(
        title: "Sales",
        themeColor: Colors.green,
        icon: Icons.point_of_sale_outlined,
      ));
    } else if (action == "account_sales") {
      context.navigateToNext(const SalesScreen(
        title: "Account Sales",
        themeColor: Color.fromARGB(255, 238, 130, 166),
        icon: Icons.receipt_long_outlined,
      ));
    } else if (action == "sales_order") {
      context.navigateToNext(const SalesScreen(
        title: "Sales Order",
        themeColor: Color.fromARGB(255, 44, 133, 211),
        icon: Icons.shopping_cart_outlined,
      ));
    } else if (action == "quotes") {
      context.navigateToNext(const SalesScreen(
        title: "Quotes",
        themeColor: Colors.orange,
        icon: Icons.request_quote_outlined,
      ));
    } else if (action == "lay_bys") {
      context.navigateToNext(const SalesScreen(
        title: "Lay-bys",
        themeColor: Color.fromARGB(255, 152, 86, 165),
        icon: Icons.inventory_2_outlined,
      ));
    } else {
      context.navigateToNext(const ComingSoonScreen());
    }
  }

  Widget _buildGridItem(
    Map<String, dynamic> itemData,
    BuildContext context,
    int index,
    int columnCount, {
    bool isTransaction = false,
  }) {
    final colors = context.appColors;
    final bool isTablet = MediaQuery.of(context).size.shortestSide >= 600;

    final double scale = isTablet
        ? (MediaQuery.of(context).size.shortestSide / 768).clamp(0.85, 1.3)
        : 1.0;
    final double titleSize = isTablet ? (14 * scale).clamp(14.0, 19.0) : 14.0;
    final double subTitleSize =
        isTablet ? (11 * scale).clamp(11.0, 14.0) : 12.0;
    final double iconSize = isTablet ? (36 * scale).clamp(32.0, 48.0) : 22.0;

    final bool isComingSoon = itemData['comingSoon'] ?? false;
    final Color itemColor = itemData['color'] ?? kPrimaryColor;
    
    // Style adjustments for inactive/coming soon cards
    // For transaction items (non-coming-soon), use kPrimaryColor like info items
    final Color effectiveTitleColor = isComingSoon 
        ? Colors.grey.shade500 
        : kPrimaryColor;
    final Color effectiveSubtitleColor = isComingSoon 
        ? Colors.grey.shade400 
        : colors.onSurfaceMuted;
    final Color effectiveIconColor = isComingSoon 
        ? Colors.grey.shade500 
        : kPrimaryColor;
    final Color? bgColor = isComingSoon
      ? (colors.isDark ? Colors.white10 : Colors.grey.shade200)
      : null;
    final LinearGradient? bgGradient = isComingSoon
      ? null
      : (colors.isDark ? colors.glassGradient : colors.glassGradient);

    return AnimationConfiguration.staggeredGrid(
      position: index,
      duration: const Duration(milliseconds: 1000),
      columnCount: columnCount,
      child: ScaleAnimation(
        child: FadeInAnimation(
          child: InkWell(
            onTap: () => _handleNavigation(itemData['action'] ?? "coming_soon", context),
            borderRadius: BorderRadius.circular(15),
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: bgColor,
                    gradient: bgGradient,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: isComingSoon ? Colors.transparent : colors.glassBorder,
                      width: 1.5,
                    ),
                    boxShadow: isComingSoon ? [] : [
                      BoxShadow(
                        color: colors.cardShadow,
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: (isTransaction && !isComingSoon) ? 20 : 12,
                      right: 12,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                itemData['title'],
                                style: getSmartTitle(
                                  color: effectiveTitleColor,
                                  fontSize: titleSize,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Icon(itemData['icon'], size: iconSize, color: effectiveIconColor),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                itemData['subTitle'],
                                style: TextStyle(
                                  color: effectiveSubtitleColor,
                                  fontSize: subTitleSize,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                // Vertical line indicator for transaction items
                if (isTransaction && !isComingSoon)
                  Positioned(
                    top: 1.5,
                    bottom: 1.5,
                    left: 0,
                    child: Container(
                      width: 10.5,
                      decoration: BoxDecoration(
                        color: itemColor,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(14),
                          bottomLeft: Radius.circular(14),
                        ),
                      ),
                    ),
                  ),
                // Corner badge for transaction items (commented out)
                // if (isTransaction && !isComingSoon)
                //   Positioned(
                //     top: 0,
                //     left: 0,
                //     child: ClipPath(
                //       clipper: _CornerTriangleClipper(),
                //       child: Container(
                //         width: 30,
                //         height: 30,
                //         decoration: BoxDecoration(
                //           color: itemColor,
                //           borderRadius: const BorderRadius.only(
                //             topLeft: Radius.circular(15),
                //           ),
                //         ),
                //       ),
                //     ),
                //   ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- DATA SOURCES ---

  final List<Map<String, dynamic>> _transactionItems = [
    {
      "title": "Sales",
      "subTitle": "Process sales",
      "icon": Icons.point_of_sale_outlined,
      "color": Colors.green.shade600,
      "comingSoon": false,
      "action": "sales"
    },
    {
      "title": "Account Sales",
      "subTitle": "Invoice customers",
      "icon": Icons.receipt_long_outlined,
      "color": const Color.fromARGB(255, 238, 130, 166),
      "comingSoon": false,
      "action": "account_sales"
    },
    {
      "title": "Sales Order",
      "subTitle": "Create orders",
      "icon": Icons.shopping_cart_outlined,
      "color": const Color.fromARGB(255, 44, 133, 211),
      "comingSoon": false,
      "action": "sales_order"
    },
    {
      "title": "Quotes",
      "subTitle": "Issue estimates",
      "icon": Icons.request_quote_outlined,
      "color": Colors.orange.shade500,
      "comingSoon": false,
      "action": "quotes"
    },
    {
      "title": "Lay-bys",
      "subTitle": "Manage lay-bys",
      "icon": Icons.inventory_2_outlined,
      "color": const Color.fromARGB(255, 152, 86, 165),
      "comingSoon": false,
      "action": "lay_bys"
    },
    {
      "title": "Goods Received",
      "subTitle": "Coming soon",
      "icon": Icons.local_shipping_outlined,
      "color": Colors.grey,
      "comingSoon": true,
      "action": "coming_soon"
    },
    {
      "title": "Purchase Orders",
      "subTitle": "Coming soon",
      "icon": Icons.shopping_bag_outlined,
      "color": Colors.grey,
      "comingSoon": true,
      "action": "coming_soon"
    },
    {
      "title": "Return Goods",
      "subTitle": "Coming soon",
      "icon": Icons.assignment_return_outlined,
      "color": Colors.grey,
      "comingSoon": true,
      "action": "coming_soon"
    },
  ];

  final List<Map<String, dynamic>> _infoItems = [
    {
      "title": "Stock-Lookup",
      "subTitle": "Search inventory",
      "icon": Icons.inventory_2_outlined,
      "color": kPrimaryColor,
      "comingSoon": false,
      "action": "stock_lookup"
    },
    {
      "title": "Customers",
      "subTitle": "Search customers",
      "icon": Icons.people_outline,
      "color": kPrimaryColor,
      "comingSoon": false,
      "action": "customer_lookup"
    },
    {
      "title": "Suppliers",
      "subTitle": "Coming soon",
      "icon": Icons.business_outlined,
      "color": Colors.grey,
      "comingSoon": true,
      "action": "coming_soon"
    },
  ];
}

class _CornerTriangleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}