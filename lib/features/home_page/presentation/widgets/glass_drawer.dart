import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:rmstock_scanner/features/home_page/presentation/widgets/shopfronts_dialog.dart'
    show ShopfrontsDialog;
import 'package:rmstock_scanner/features/loading_splash/presentation/BLoC/loading_splash_bloc.dart';
import 'package:rmstock_scanner/features/loading_splash/presentation/BLoC/loading_splash_states.dart';
import 'package:rmstock_scanner/utils/navigation_extension.dart';
import '../../../../constants/colors.dart';
import '../../../../constants/txt_styles.dart';
import '../../../../entities/vos/network_computer_vo.dart';
import '../../../../utils/global_var_utils.dart';
import '../../../stock_lookup/presentation/screens/stock_lookup_screen.dart'
    hide kPrimaryColor;
import '../BLoC/home_screen_bloc.dart';
import '../BLoC/home_screen_events.dart';
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
                    padding: const EdgeInsets.only(left: 28, right: 28), // Added right padding
                    child: BlocBuilder<NetworkSavedPathValidationBloc, LoadingSplashStates>(
                      builder: (context, state) {
                        String shopText;
                        if (state is ConnectionValid) {
                          shopText = AppGlobals.instance.shopfront == null
                              ? "RM-Shopfront"
                              : (AppGlobals.instance.shopfront!).split(r'\').last;
                        } else {
                          shopText = "Connect to a shopfront...";
                        }

                        return Text(
                          shopText,
                          style: const TextStyle(
                            color: kSecondaryColor,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        );
                      },
                    ),
                  ),

                  Expanded(child: dashBoardView(scrollController)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget dashBoardView(ScrollController? scrollController) {
    return AnimationLimiter(
      child: GridView.builder(
        controller: scrollController,
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
          childAspectRatio: 2.4 / 1,
        ),
        itemCount: _menuItems.length,
        itemBuilder: (context, index) {
          return InkWell(
            onTap: () {
              if (index == 0) {
                context.read<ShopfrontBloc>().add(
                  FetchShops(
                    path: AppGlobals.instance.currentPath ?? '',
                    ipAddress: AppGlobals.instance.currentHostIp ?? "",
                  ),
                );
                showDialog(
                  context: context,
                  builder: (context) {
                    return ShopfrontsDialog(
                      pc: NetworkComputerVO(
                        ipAddress: AppGlobals.instance.currentHostIp ?? "",
                        hostName: AppGlobals.instance.hostName ?? "",
                      ),
                      previousPath: AppGlobals.instance.currentPath ?? '',
                    );
                  },
                );
              } else if (index == 1) {
                context.navigateToNext(const StockLookupScreen());
              } else {
                context.navigateToNext(const ComingSoonScreen());
              }
            },
            child: _buildGridItem(
              _menuItems[index]['title'],
              _menuItems[index]['subTitle'],
              _menuItems[index]['icon'],
              context,
              index,
            ),
          );
        },
      ),
    );
  }

  Widget _buildGridItem(
      String title,
      String subTitle,
      IconData icon,
      BuildContext context,
      int index,
      ) {
    return AnimationConfiguration.staggeredGrid(
      position: index,
      duration: const Duration(milliseconds: 1500),
      columnCount: 2,
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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Responsive Fix: Use Expanded instead of hardcoded width
                        Expanded(
                          child: Text(
                            title,
                            style: getSmartTitle(
                              color: kPrimaryColor,
                              fontSize: 12,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 5), // Prevent overlap
                        Icon(icon, size: 22, color: kPrimaryColor),
                      ],
                    ),
                  ),
                  const SizedBox(height: 3),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            subTitle,
                            style: const TextStyle(
                              color: kGreyColor,
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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
      "subTitle": "Connect to your Shopfront",
      "icon": Icons.shop_2_outlined,
    },
    {
      "title": "Stock-Lookup",
      "subTitle": "Search your inventory",
      "icon": Icons.inventory_2_outlined,
    },
    {
      "title": "Mobile Sales",
      "subTitle": "Do instant counter sales",
      "icon": Icons.point_of_sale_outlined,
    },
    {
      "title": "Purchase Orders",
      "subTitle": "Order directly to supplier",
      "icon": Icons.shopping_bag_outlined,
    },
    {
      "title": "Goods Received",
      "subTitle": "Easily receive arrivals",
      "icon": Icons.local_shipping_outlined,
    },
    {
      "title": "Quotes & SO",
      "subTitle": "Issue quotes & Sales Orders",
      "icon": Icons.request_quote_outlined,
    },
    {
      "title": "Returns",
      "subTitle": "Return goods to supplier",
      "icon": Icons.assignment_return_outlined,
    },
    {
      "title": "Pricing Changes",
      "subTitle": "Instantly update your pricing",
      "icon": Icons.price_change_outlined,
    },
    {
      "title": "Barcode Labels",
      "subTitle": "Print & Adjust labels",
      "icon": Icons.qr_code_2_outlined,
    },
    {
      "title": "Reporting",
      "subTitle": "View & Print out Reports",
      "icon": Icons.newspaper_outlined,
    },
    {
      "title": "Customers",
      "subTitle": "Search customers' details",
      "icon": Icons.people,
    },
    {
      "title": "Suppliers",
      "subTitle": "Search suppliers' details",
      "icon": Icons.newspaper_outlined,
    },
  ];
}