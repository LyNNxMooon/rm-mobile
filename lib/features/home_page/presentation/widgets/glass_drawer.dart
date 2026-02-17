import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:rmstock_scanner/features/home_page/presentation/widgets/shopfronts_dialog.dart'
    show ShopfrontsDialog;
import 'package:rmstock_scanner/utils/navigation_extension.dart';
import '../../../../constants/colors.dart';
import '../../../../constants/txt_styles.dart';
import '../../../../entities/vos/network_computer_vo.dart';
import '../../../../local_db/local_db_dao.dart';
import '../../../../utils/global_var_utils.dart';
import '../../../stock_lookup/presentation/screens/stock_lookup_screen.dart';
import '../BLoC/home_screen_bloc.dart';
import '../BLoC/home_screen_events.dart';
import '../BLoC/home_screen_states.dart';
import '../screens/coming_soon_screen.dart';

class GlassDrawer extends StatefulWidget {
  const GlassDrawer({super.key});

  @override
  State<GlassDrawer> createState() => _GlassDrawerState();
}

class _GlassDrawerState extends State<GlassDrawer> {
  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.535,
      minChildSize: 0.535,
      maxChildSize: 0.88,
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
                color: kSecondaryColor.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
                border: Border.all(color: kSecondaryColor.withOpacity(0.2)),
                boxShadow: [
                  BoxShadow(blurRadius: 20, color: kThirdColor.withOpacity(.1)),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 12),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: kSecondaryColor.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),

                  Padding(
                    padding: const EdgeInsets.only(
                      left: 28,
                      right: 28,
                    ),
                    child:
                    BlocBuilder<ShopFrontConnectionBloc, ShopfrontConnectionStates>(
                      builder: (context, state) {
                        final shop = AppGlobals.instance.shopfront;
                        //final host = AppGlobals.instance.hostName;
                        final shopText = (shop == null || shop.isEmpty)
                            ? "Connect to a shopfront..."
                            : shop.split(r'\\').last;

                        return Text(
                          shopText,
                          style: const TextStyle(
                            color: kSecondaryColor,
                            fontSize: 18,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        );
                      },
                    ),
                  ),

                  Expanded(child: dashBoardView(scrollController)),
                  const SizedBox(height: 10,)
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget dashBoardView(ScrollController? scrollController) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final double height = constraints.maxHeight;

        int crossAxisCount = 2;
        if (width > 600) crossAxisCount = 3;
        if (width > 900) crossAxisCount = 4;

        const double padding = 50.0; // Horizontal padding total
        double spacing = width > 600 ? 20.0 : 15.0; // More gap on tablets

        // Calculate how many rows we have
        int rowCount = (_menuItems.length / crossAxisCount).ceil();

        double targetHeight = 85.0;

        double naturalGridHeight = (rowCount * targetHeight) + ((rowCount - 1) * spacing) + 40;

        // If the screen is tall (Tablet Portrait), we have extra vertical space.
        if (height > naturalGridHeight) {
          double extraSpace = height - naturalGridHeight;
          double extraPerItem = extraSpace / rowCount;

          // Cap the growth so buttons don't become massive towers.
          // Slightly increased cap to 50.0 since we removed the footer.
          if (extraPerItem > 50.0) extraPerItem = 50.0;

          targetHeight += extraPerItem;
        }

        final double totalSpacing = spacing * (crossAxisCount - 1);
        final double availableWidth = width - padding - totalSpacing;
        final double itemWidth = availableWidth / crossAxisCount;
        final double childAspectRatio = itemWidth / targetHeight;

        return AnimationLimiter(
          child: GridView.builder(
            controller: scrollController,
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: spacing,
              mainAxisSpacing: spacing,
              childAspectRatio: childAspectRatio,
            ),
            itemCount: _menuItems.length,
            itemBuilder: (context, index) {
              return InkWell(
                onTap: () {
                  _handleNavigation(index, context);
                },
                child: _buildGridItem(
                  _menuItems[index]['title'],
                  _menuItems[index]['subTitle'],
                  _menuItems[index]['icon'],
                  context,
                  index,
                  crossAxisCount,
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _handleNavigation(int index, BuildContext context) async {
    if (index == 0) {
      final String? savedApiKey = await LocalDbDAO.instance.getApiKey();
      final String? savedPortText = await LocalDbDAO.instance.getHostPort();
      final int? savedPort = int.tryParse(savedPortText ?? "");
      final String hostIp = AppGlobals.instance.currentHostIp ?? "";

      if (hostIp.isEmpty || (savedApiKey ?? "").isEmpty || savedPort == null) {
        return;
      }

      context.read<ShopfrontBloc>().add(
        FetchShopsFromApi(
          ipAddress: hostIp,
          port: savedPort,
          apiKey: savedApiKey!,
        ),
      );

      // Old setup disabled:
      // context.read<ShopfrontBloc>().add(
      //   FetchShops(
      //     path: AppGlobals.instance.currentPath ?? '',
      //     ipAddress: AppGlobals.instance.currentHostIp ?? "",
      //   ),
      // );

      showDialog(
        context: context,
        builder: (context) {
          return ShopfrontsDialog(
            pc: NetworkComputerVO(
              ipAddress: AppGlobals.instance.currentHostIp ?? "",
              hostName: AppGlobals.instance.hostName ?? "",
            ),
            previousPath: "",
            isPairedFlow: true,
            port: savedPort,
            apiKey: savedApiKey,
          );
        },
      );
    } else if (index == 1) {
      context.read<FetchStockBloc>().add(
        StartSyncEvent(ipAddress: AppGlobals.instance.currentHostIp ?? ""),
      );
      context.navigateToNext(const StockLookupScreen());
    } else {
      context.navigateToNext(const ComingSoonScreen());
    }
  }

  Widget _buildGridItem(
      String title,
      String subTitle,
      IconData icon,
      BuildContext context,
      int index,
      int columnCount,
      ) {
    return AnimationConfiguration.staggeredGrid(
      position: index,
      duration: const Duration(milliseconds: 1500),
      columnCount: columnCount,
      child: ScaleAnimation(
        child: FadeInAnimation(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  kSecondaryColor.withOpacity(0.95),
                  kSecondaryColor.withOpacity(0.70),
                ],
              ),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: kSecondaryColor.withOpacity(0.6),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: kThirdColor.withOpacity(0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: getSmartTitle(
                              color: kPrimaryColor,
                              fontSize: 14,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Icon(icon, size: 22, color: kPrimaryColor),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            subTitle,
                            style: const TextStyle(
                              color: kGreyColor,
                              fontSize: 13,
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
          ),
        ),
      ),
    );
  }

  final List<Map<String, dynamic>> _menuItems = [
    {
      "title": "RM Shopfront",
      "subTitle": "Select Shopfront",
      "icon": Icons.shop_2_outlined,
    },
    {
      "title": "Stock-Lookup",
      "subTitle": "Search inventory",
      "icon": Icons.inventory_2_outlined,
    },
    {
      "title": "Mobile Sales",
      "subTitle": "Do Counter sales",
      "icon": Icons.point_of_sale_outlined,
    },
    {
      "title": "Quotes & SO",
      "subTitle": "Issue Quotes & SO",
      "icon": Icons.request_quote_outlined,
    },
    {
      "title": "Purchase Orders",
      "subTitle": "Order to supplier",
      "icon": Icons.shopping_bag_outlined,
    },
    {
      "title": "Goods Received",
      "subTitle": "Receive arrivals",
      "icon": Icons.local_shipping_outlined,
    },
    {
      "title": "Returns",
      "subTitle": "Return goods",
      "icon": Icons.assignment_return_outlined,
    },
    {
      "title": "Pricing Changes",
      "subTitle": "Update pricing",
      "icon": Icons.price_change_outlined,
    },
    {
      "title": "Barcode Labels",
      "subTitle": "Print & Adjust labels",
      "icon": Icons.qr_code_2_outlined,
    },
    {
      "title": "Reporting",
      "subTitle": "Print Reports",
      "icon": Icons.newspaper_outlined,
    },
    {
      "title": "Customers",
      "subTitle": "Search customers",
      "icon": Icons.people,
    },
    {
      "title": "Suppliers",
      "subTitle": "Search suppliers",
      "icon": Icons.newspaper_outlined,
    },
  ];
}
