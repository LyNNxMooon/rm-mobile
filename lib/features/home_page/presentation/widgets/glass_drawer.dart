import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:rmmobile/utils/navigation_extension.dart';
import 'package:rmmobile/utils/dependency_injection_utils.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

import '../../../../constants/colors.dart';
import '../../../../constants/theme_colors.dart';
import '../../../../constants/txt_styles.dart';
import '../../../../utils/global_var_utils.dart';
import '../../../../utils/responsive_utils.dart';
import '../../../stock_lookup/presentation/screens/stock_lookup_screen.dart';
import '../../../customer_lookup/presentation/screens/customer_lookup_screen.dart';
import '../../../customer_lookup/presentation/BLoC/customer_lookup_bloc.dart';
import '../../../customer_lookup/presentation/BLoC/customer_lookup_states.dart';
import '../../../transactions/presentation/screens/sales_screen.dart';
import '../../../transactions/presentation/BLoC/sales_bloc.dart';
import '../BLoC/home_screen_bloc.dart';
import '../BLoC/home_screen_states.dart';
import '../BLoC/session_counts_cubit.dart';
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

class _GlassDrawerState extends State<GlassDrawer> with RouteAware {
  @override
  void initState() {
    super.initState();
    _loadSessionCounts();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh counts when returning to this screen
    _loadSessionCounts();
  }

  void _loadSessionCounts() {
    context.read<SessionCountsCubit>().loadSessionCounts();
  }

  bool _isSyncInProgress(BuildContext context) {
    return context.read<FetchStockBloc>().state is FetchStockProgress ||
        context.read<FetchCustomerBloc>().state is FetchCustomerProgress;
  }

  bool _blockTransactionsIfSyncing(BuildContext context) {
    if (!_isSyncInProgress(context)) return false;
    showTopSnackBar(
      Overlay.of(context),
      const CustomSnackBar.info(
        message: "Sync in progress. Please wait.",
      ),
    );
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    final sheet = ScrollConfiguration(
      // Allow mouse drag for tablets/desktop in addition to touch
      behavior: ScrollConfiguration.of(context).copyWith(
        dragDevices: {
          PointerDeviceKind.touch,
          PointerDeviceKind.mouse,
          PointerDeviceKind.stylus,
          PointerDeviceKind.trackpad,
        },
      ),
      child: DraggableScrollableSheet(
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
                  SizedBox(height: context.isTablet ? 15 : 14),
                  Expanded(child: dashBoardView(scrollController)),
                ],
              ),
            ),
          ),
        );
      },
      ),
    );

    return sheet;
  }

  Widget _buildSectionTitle(String title, BuildContext context) {
    final colors = context.appColors;
    final bool isTablet = context.isTablet;
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
        final bool isTablet = context.isTablet;
        final bool isTabletPortrait =
            isTablet && context.isPortrait;
        final bool isLargeTablet = context.isLargeTablet;

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

        final bottomPadding = MediaQuery.of(context).padding.bottom;
        return ListView(
          controller: scrollController,
          padding: EdgeInsets.only(top: isTablet ? 10 : 8, bottom: 40 + bottomPadding),
          physics: const ClampingScrollPhysics(),
          children: [
            // --- SECTION 1: TRANSACTIONS ---
            _buildSectionTitle("Transactions", context),
            BlocBuilder<SessionCountsCubit, SessionCountsState>(
              builder: (context, sessionState) {
                final sessionCounts = sessionState.counts;
                return AnimationLimiter(
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
                      final item = _transactionItems[index];
                      // Map action to session type for badge count
                      String? sessionType;
                      switch (item['action']) {
                        case 'account_sales':
                          sessionType = 'Account Sales';
                          break;
                        case 'sales_order':
                          sessionType = 'Sales Order';
                          break;
                        case 'quotes':
                          sessionType = 'Quotes';
                          break;
                        case 'lay_bys':
                          sessionType = 'Lay-bys';
                          break;
                      }
                      final badgeCount = sessionType != null ? (sessionCounts[sessionType] ?? 0) : 0;
                      
                      return _buildGridItem(
                        item,
                        context,
                        index,
                        crossAxisCount,
                        isTransaction: true,
                        badgeCount: badgeCount,
                      );
                    },
                  ),
                );
              },
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
      if (_blockTransactionsIfSyncing(context)) return;
      context.navigateToNext(
        BlocProvider(
          create: (_) => sl<SalesBloc>(),
          child: const SalesScreen(
            title: "Sales",
            themeColor: Colors.green,
            icon: Icons.point_of_sale_outlined,
          ),
        ),
      ).then((_) => _loadSessionCounts());
    } else if (action == "account_sales") {
      if (_blockTransactionsIfSyncing(context)) return;
      if (!AppGlobals.instance.hasPermission("Transaction_Sales")) {
        showTopSnackBar(
          Overlay.of(context),
          const CustomSnackBar.error(
            message: "You do not have permission to access Account Sales.",
          ),
        );
        return;
      }
      context.navigateToNext(
        BlocProvider(
          create: (_) => sl<SalesBloc>(),
          child: const SalesScreen(
            title: "Account Sales",
            themeColor: Color.fromARGB(255, 238, 130, 166),
            icon: Icons.receipt_long_outlined,
          ),
        ),
      ).then((_) => _loadSessionCounts());
    } else if (action == "sales_order") {
      if (_blockTransactionsIfSyncing(context)) return;
      if (!AppGlobals.instance.hasPermission("Transaction_Sales")) {
        showTopSnackBar(
          Overlay.of(context),
          const CustomSnackBar.error(
            message: "You do not have permission to access Sales Order.",
          ),
        );
        return;
      }
      context.navigateToNext(
        BlocProvider(
          create: (_) => sl<SalesBloc>(),
          child: const SalesScreen(
            title: "Sales Order",
            themeColor: Color.fromARGB(255, 44, 133, 211),
            icon: Icons.shopping_cart_outlined,
          ),
        ),
      ).then((_) => _loadSessionCounts());
    } else if (action == "quotes") {
      if (_blockTransactionsIfSyncing(context)) return;
      if (!AppGlobals.instance.hasPermission("Transaction_Sales")) {
        showTopSnackBar(
          Overlay.of(context),
          const CustomSnackBar.error(
            message: "You do not have permission to access Quotes.",
          ),
        );
        return;
      }
      context.navigateToNext(
        BlocProvider(
          create: (_) => sl<SalesBloc>(),
          child: const SalesScreen(
            title: "Quotes",
            themeColor: Colors.orange,
            icon: Icons.request_quote_outlined,
          ),
        ),
      ).then((_) => _loadSessionCounts());
    } else if (action == "lay_bys") {
      if (_blockTransactionsIfSyncing(context)) return;
      if (!AppGlobals.instance.hasPermission("Transaction_Sales")) {
        showTopSnackBar(
          Overlay.of(context),
          const CustomSnackBar.error(
            message: "You do not have permission to access Lay-bys.",
          ),
        );
        return;
      }
      context.navigateToNext(
        BlocProvider(
          create: (_) => sl<SalesBloc>(),
          child: const SalesScreen(
            title: "Lay-bys",
            themeColor: Color.fromARGB(255, 152, 86, 165),
            icon: Icons.inventory_2_outlined,
          ),
        ),
      ).then((_) => _loadSessionCounts());
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
    int badgeCount = 0,
  }) {
    final colors = context.appColors;
    final bool isTablet = context.isTablet;

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
      : (colors.isDark ? colors.onSurfaceMuted : kThirdColor.withOpacity(0.78));
    final Color effectiveIconColor = isComingSoon 
        ? Colors.grey.shade500 
        : kPrimaryColor;
    final Color? bgColor = isComingSoon
      ? (colors.isDark ? Colors.white10 : Colors.grey.shade200)
      : (colors.isDark ? null : Colors.white);
    final LinearGradient? bgGradient = isComingSoon
      ? null
      : (colors.isDark ? colors.glassGradient : null);

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
                // Session count badge
                if (isTransaction && !isComingSoon && badgeCount > 0)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      constraints: BoxConstraints(
                        minWidth: isTablet ? 22 : 18,
                        minHeight: isTablet ? 22 : 18,
                      ),
                      padding: EdgeInsets.all(isTablet ? 4 : 3),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.4),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          badgeCount > 99 ? '99+' : badgeCount.toString(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isTablet ? 11 : 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
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
      "title": "Sales",
      "subTitle": "Coming soon",
      "icon": Icons.point_of_sale_outlined,
      "color": Colors.grey,
      "comingSoon": true,
      "action": "coming_soon"
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