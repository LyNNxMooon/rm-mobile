import 'package:alert_info/alert_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rmstock_scanner/utils/navigation_extension.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';
import '../../../../constants/colors.dart';
import '../../../../utils/global_var_utils.dart';
import '../../../../utils/log_utils.dart';
import '../../../loading_splash/presentation/BLoC/loading_splash_bloc.dart';
import '../../../loading_splash/presentation/BLoC/loading_splash_states.dart';
import '../../../stock_lookup/presentation/widgets/stock_request_error_dialog.dart';
import '../../../stocktake/presentation/screens/scanner_screen.dart';
import '../BLoC/home_screen_bloc.dart';
import '../BLoC/home_screen_events.dart';
import '../BLoC/home_screen_states.dart';
import '../widgets/action_card.dart';
import '../widgets/app_bar_session.dart';
import '../widgets/glass_drawer.dart';
import '../widgets/network_pc_dialog.dart';
import 'staff_login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();

    context.read<SettingsBloc>().add(RunHistoryCleanupEvent());
    context.read<StaffAuthBloc>().add(LoadSavedStaffSessionEvent());

    final currentParamState = context
        .read<NetworkSavedPathValidationBloc>()
        .state;

    if (currentParamState is ErrorFetchingSavedPaths ||
        currentParamState is ErrorCheckingConnection) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showNetworkDialog();
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _promptStaffLoginIfNeeded();
    });

    // Old setup disabled:
    // if (currentParamState is ConnectionValid &&
    //     context.read<ShopFrontConnectionBloc>().state
    //         is! ConnectedToShopfront) {
    //   context.read<ShopFrontConnectionBloc>().add(
    //     ConnectToShopfrontEvent(
    //       ip: AppGlobals.instance.currentHostIp ?? "",
    //       shopName: AppGlobals.instance.shopfront ?? "",
    //     ),
    //   );
    // }
  }

  Future<void> _promptStaffLoginIfNeeded() async {
    final hasShopfront = (AppGlobals.instance.shopfront ?? "")
        .trim()
        .isNotEmpty;
    if (!hasShopfront) return;

    if (!AppGlobals.instance.isStaffSignedIn) {
      await context.navigateToNext(const StaffLoginScreen());
      if (!mounted) return;
      setState(() {});
    }
  }

  void _showNetworkDialog() {
    if (ModalRoute.of(context)?.isCurrent != true) return;
    if (context.read<FetchStockBloc>().state is FetchStockProgress) return;
    logger.d("State is noticed");
    context.read<FetchingNetworkServerBloc>().add(FetchNetworkServerEvent());
    showDialog(
      context: context,
      builder: (context) {
        return const NetworkPcDialog();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Calculate the available height above the drawer (approx 45% of screen)
    // We use this to center the content dynamically.
    final double screenHeight = MediaQuery.of(context).size.height;
    final media = MediaQuery.of(context);
    final bool isTablet = media.size.shortestSide >= 600;
    final bool isTabletPortrait =
        isTablet && media.orientation == Orientation.portrait;
    final bool isSmallTablet = isTablet && media.size.shortestSide < 720;
    final bool isTabletLandscape =
        media.orientation == Orientation.landscape &&
        isTablet;
    final double topContentHeight = isTabletPortrait
        ? screenHeight * 0.43
        : (isTabletLandscape ? screenHeight * 0.44 : screenHeight * 0.42);
    final double actionCardMinHeight = isTabletPortrait
        ? (isSmallTablet
              ? (screenHeight * 0.125).clamp(112.0, 142.0)
              : (screenHeight * 0.14).clamp(124.0, 168.0))
        : (isTabletLandscape
              ? (isSmallTablet
                    ? (screenHeight * 0.135).clamp(108.0, 136.0)
                    : (screenHeight * 0.15).clamp(118.0, 160.0))
              : 0);
    final double actionToDrawerGap = isTabletPortrait
        ? 20
        : (isTabletLandscape ? 18 : (screenHeight * 0.038).clamp(16.0, 26.0));

    return MultiBlocListener(
      listeners: [
        BlocListener<NetworkSavedPathValidationBloc, LoadingSplashStates>(
          listener: (context, state) {
            if (state is ErrorFetchingSavedPaths ||
                state is ErrorCheckingConnection) {
              _showNetworkDialog();
            }
          },
        ),
        BlocListener<StaffAuthBloc, StaffAuthStates>(
          listener: (context, state) {
            if (state is StaffSignedOut || state is StaffUnauthenticated) {
              _promptStaffLoginIfNeeded();
            }
          },
        ),
      ],
      child: Scaffold(
        extendBody: true,
        backgroundColor: kPrimaryColor,
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(gradient: kGColor),
          child: SafeArea(
            bottom: false,
            top: true,
            child: Stack(
              children: [
                SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: Column(
                    children: [
                      SizedBox(height: isTabletPortrait ? 4 : 10),

                      const AppBarSession(),

                      // Replaces fixed SizedBoxes. This container fills 42% of the screen
                      // (fitting perfectly above the 53.5% drawer) and centers the items.
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight:
                              300, // Ensure it doesn't crush on small phones
                          maxHeight: topContentHeight < 300
                              ? 300
                              : topContentHeight,
                        ),
                        child: Column(
                          mainAxisAlignment:
                              MainAxisAlignment.center, // Center Vertically
                          children: [
                            logo(),

                            // Use flexible spacing inside the block if needed,
                            // or smaller fixed gaps that look good when centered.
                            SizedBox(
                              height: isTabletPortrait
                                  ? (screenHeight * 0.018).clamp(10.0, 16.0)
                                  : screenHeight * 0.03,
                            ),

                            headerTitle(),

                            SizedBox(
                              height: isTabletPortrait
                                  ? (screenHeight * 0.012).clamp(6.0, 12.0)
                                  : screenHeight * 0.02,
                            ),

                            ActionCard(
                              minHeight: actionCardMinHeight,
                              onTap: () {
                                if (context.read<FetchStockBloc>().state
                                    is FetchStockProgress) {
                                  showTopSnackBar(
                                    Overlay.of(context),
                                    const CustomSnackBar.info(
                                      message:
                                          "Stock sync in progress. Please wait.",
                                    ),
                                  );
                                  return;
                                }

                                if (!AppGlobals.instance.hasPermission(
                                  "StockManagement_Stocktake",
                                )) {
                                  showTopSnackBar(
                                    Overlay.of(context),
                                    const CustomSnackBar.error(
                                      message:
                                          "You do not have permission to start stocktaking.",
                                    ),
                                  );
                                  return;
                                }

                                final currentState = context
                                    .read<FetchStockBloc>()
                                    .state;

                                // Old setup disabled:
                                // if (currentState is! FetchStockProgress) {
                                //   context.read<ShopFrontConnectionBloc>().add(
                                //     ConnectToShopfrontEvent(
                                //       ip: AppGlobals.instance.currentHostIp ?? "",
                                //       shopName: AppGlobals.instance.shopfront ?? "",
                                //     ),
                                //   );
                                // }

                                if (currentState is! FetchStockProgress) {
                                  context.read<FetchStockBloc>().add(
                                    StartSyncEvent(
                                      ipAddress:
                                          AppGlobals.instance.currentHostIp ??
                                          "",
                                    ),
                                  );
                                }

                                context.navigateToNext(const ScannerScreen());
                              },
                              title: "Start Stocktaking",
                              subtitle: "Begin Counting Inventory Items",
                            ),
                            SizedBox(
                              height: actionToDrawerGap,
                            ),
                            if (isTabletLandscape)
                              const SizedBox(height: 10),
                          ],
                        ),
                      ),

                      syncWatcher(),

                      SizedBox(height: isTabletLandscape ? 140 : 120),
                    ],
                  ),
                ),

                const GlassDrawer(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget logo() {
    final media = MediaQuery.of(context);
    final bool isTablet = media.size.shortestSide >= 600;
    final double horizontalPad = isTablet ? 60 : 25;
    final double logoHeight = isTablet ? 82 : 75;
    return Center(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: horizontalPad),
        width: double.infinity,
        height: logoHeight,
        child: Image.asset("assets/images/trademark.png", fit: BoxFit.contain),
      ),
    );
  }

  Widget headerTitle() {
    return ShaderMask(
      shaderCallback: (bounds) {
        return const LinearGradient(
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
          colors: [
            Color(0xC786D0EF),
            Color(0xFFFFFFFF),
            Color(0xFFCCC8C8),
            Color(0xC760C3EE),
            Color(0xFFFFFFFF),
            Color(0xC760C3EE),
          ],
        ).createShader(bounds);
      },
      blendMode: BlendMode.srcIn,
      child: const Text(
        "Welcome to RM - Mobile",
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget syncWatcher() {
    return BlocListener<ShopFrontConnectionBloc, ShopfrontConnectionStates>(
      listenWhen: (previous, current) =>
          previous is! ConnectedToShopfront && current is ConnectedToShopfront,
      listener: (context, state) {
        if (state is ConnectedToShopfront) {
          context.read<FetchStockBloc>().add(
            StartSyncEvent(ipAddress: AppGlobals.instance.currentHostIp ?? ""),
          );

          AlertInfo.show(
            context: context,
            text: "Stock requested!",
            typeInfo: TypeInfo.success,
            backgroundColor: kSecondaryColor,
            iconColor: kPrimaryColor,
            textColor: kThirdColor,
            position: MessagePosition.top,
            padding: 70,
          );
        }

        if (state is ShopfrontConnectionError) {
          showTopSnackBar(
            Overlay.of(context),
            CustomSnackBar.error(message: state.message),
          );

          showDialog(
            context: context,
            builder: (context) {
              return StockRequestErrorDialog(message: state.message);
            },
          );
        }
      },
      child: const SizedBox(),
    );
  }
}
