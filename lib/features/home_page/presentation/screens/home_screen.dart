
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rmstock_scanner/utils/navigation_extension.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';
import '../../../../constants/colors.dart';
import '../../../../local_db/local_db_dao.dart';
import '../../../../local_db/sqlite/sqlite_constants.dart';
import '../../../../utils/global_var_utils.dart';
import '../../../../utils/log_utils.dart';
import '../../../customer_lookup/presentation/BLoC/customer_lookup_bloc.dart';
import '../../../customer_lookup/presentation/BLoC/customer_lookup_events.dart';
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
  bool _autoAuthAttempted = false;
  bool _autoConnectAttempted = false;

  _DrawerSizes _resolveDrawerSizes(MediaQueryData media) {
    final bool isTablet = media.size.shortestSide >= 600;
    final bool isPortrait = media.orientation == Orientation.portrait;
    final bool isTabletPortrait = isTablet && isPortrait;

    double initialChildSize = 0.535;
    double minChildSize = 0.535;
    double maxChildSize = 0.88;

    if (isTabletPortrait) {
      initialChildSize = media.size.height >= 1100 ? 0.58 : 0.56;
      minChildSize = media.size.height >= 1100 ? 0.56 : 0.54;
      maxChildSize = 0.91;
    } else if (isPortrait) {
      initialChildSize = 0.535;
      minChildSize = 0.535;
      maxChildSize = 0.88;
    } else if (isTablet) {
      // Lower drawer start for tablet landscape (more gap from action card)
      final double pxOffset = 30 / media.size.height;
      initialChildSize = 0.50 - pxOffset;
      minChildSize = 0.48 - pxOffset;
      maxChildSize = 0.90;
    } else {
      initialChildSize = 0.49;
      minChildSize = 0.47;
      maxChildSize = 0.86;
    }

    return _DrawerSizes(
      initialChildSize: initialChildSize,
      minChildSize: minChildSize,
      maxChildSize: maxChildSize,
    );
  }

  @override
  void initState() {
    super.initState();

    context.read<SettingsBloc>().add(RunHistoryCleanupEvent());

    final currentParamState = context
        .read<NetworkSavedPathValidationBloc>()
        .state;

    if (currentParamState is ErrorFetchingSavedPaths ||
        currentParamState is ErrorCheckingConnection) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final hasSavedShopfront =
            (AppGlobals.instance.shopfront ?? "").trim().isNotEmpty;
        if (!hasSavedShopfront || !AppGlobals.instance.isStaffSignedIn) {
          _showNetworkDialog();
        }
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (currentParamState is ConnectionValid) {
        _attemptAutoShopfrontConnect();
      } else {
        _promptStaffLoginIfNeeded();
      }
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

  Future<void> _promptStaffLoginIfNeeded({bool force = false}) async {
    final hasShopfront = (AppGlobals.instance.shopfront ?? "")
        .trim()
        .isNotEmpty;
    if (!force && !hasShopfront) return;

    if (!AppGlobals.instance.isStaffSignedIn || force) {
      await context.navigateToNext(const StaffLoginScreen());
      if (!mounted) return;
      setState(() {});
    }
  }

  Future<void> _attemptAutoAuthIfPossible() async {
    if (_autoAuthAttempted || !mounted) return;

    if (context.read<ShopFrontConnectionBloc>().state
        is! ConnectedToShopfront) {
      logger.d("Auto-auth skipped: shopfront not connected yet.");
      return;
    }

    final ip = (AppGlobals.instance.currentHostIp ?? "").trim();
    final portStr = await LocalDbDAO.instance.getHostPort();
    final apiKey = await LocalDbDAO.instance.getApiKey();
    final shopfrontId = await LocalDbDAO.instance.getShopfrontId();
    final shopfrontName = await LocalDbDAO.instance.getShopfrontName();
    final staffNo =
        (await LocalDbDAO.instance.getAppConfig(kStaffNoKey) ?? "").trim();
    final staffPassword =
        (await LocalDbDAO.instance.getAppConfig(kStaffPasswordKey) ?? "")
            .trim();

    final int? port = int.tryParse(portStr ?? "");
    final bool missingConnection =
        ip.isEmpty || port == null || apiKey == null || apiKey.isEmpty;
    final bool missingShopfront =
        (shopfrontId ?? "").trim().isEmpty ||
        (shopfrontName ?? "").trim().isEmpty;

    if (missingConnection || missingShopfront) {
      logger.d(
        "Auto-auth skipped: missing connection/shopfront info.",
      );
      _promptStaffLoginIfNeeded();
      return;
    }

    if (staffNo.isEmpty) {
      logger.d("Auto-auth skipped: missing saved staff number.");
      _promptStaffLoginIfNeeded();
      return;
    }

    _autoAuthAttempted = true;
    logger.d("Auto-auth dispatching AuthenticateStaffEvent.");
    context.read<StaffAuthBloc>().add(
      AuthenticateStaffEvent(
        ip: ip,
        port: port,
        apiKey: apiKey,
        shopfrontId: shopfrontId!.trim(),
        shopfrontName: shopfrontName!.trim(),
        staffNo: staffNo,
        password: staffPassword,
      ),
    );
  }

  Future<void> _attemptAutoShopfrontConnect() async {
    if (_autoConnectAttempted || !mounted) return;
    if (context.read<ShopFrontConnectionBloc>().state
        is ConnectedToShopfront) {
      return;
    }

    final savedIp = (AppGlobals.instance.currentHostIp ?? "").trim();
    final portStr = await LocalDbDAO.instance.getHostPort();
    final apiKey = await LocalDbDAO.instance.getApiKey();
    final shopfrontId = await LocalDbDAO.instance.getShopfrontId();
    final shopfrontName = await LocalDbDAO.instance.getShopfrontName();

    final int? port = int.tryParse(portStr ?? "");
    final bool missingConnection =
        savedIp.isEmpty || port == null || apiKey == null || apiKey.isEmpty;
    final bool missingShopfront =
        (shopfrontId ?? "").trim().isEmpty ||
        (shopfrontName ?? "").trim().isEmpty;

    if (missingConnection || missingShopfront) {
      logger.d("Auto-connect skipped: missing connection/shopfront info.");
      return;
    }

    _autoConnectAttempted = true;
    logger.d("Auto-connecting shopfront via API.");
    context.read<ShopFrontConnectionBloc>().add(
      ConnectToShopfrontApiEvent(
        ip: savedIp,
        port: port,
        apiKey: apiKey,
        shopfrontId: shopfrontId!.trim(),
        shopfrontName: shopfrontName!.trim(),
      ),
    );
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
    final drawerSizes = _resolveDrawerSizes(media);
    final double topContentHeight = isTablet
      ? screenHeight * (1 - drawerSizes.initialChildSize)
      : (isTabletPortrait
        ? screenHeight * 0.43
        : (isTabletLandscape ? screenHeight * 0.44 : screenHeight * 0.42));
    final double actionCardMinHeight = isTabletPortrait
        ? (isSmallTablet
              ? (screenHeight * 0.125).clamp(112.0, 142.0)
              : (screenHeight * 0.14).clamp(124.0, 168.0))
        : (isTabletLandscape
              ? (isSmallTablet
                    ? (screenHeight * 0.135).clamp(108.0, 136.0)
                    : (screenHeight * 0.15).clamp(118.0, 160.0))
              : 0);
    final double actionToDrawerGap = isTablet
        ? 80
        : (screenHeight * 0.038).clamp(16.0, 26.0);

    return MultiBlocListener(
      listeners: [
        BlocListener<NetworkSavedPathValidationBloc, LoadingSplashStates>(
          listener: (context, state) {
            if (state is ConnectionValid) {
              _attemptAutoShopfrontConnect();
            }
            if (state is ErrorFetchingSavedPaths ||
                state is ErrorCheckingConnection) {
              final hasSavedShopfront =
                  (AppGlobals.instance.shopfront ?? "").trim().isNotEmpty;
              if (!hasSavedShopfront || !AppGlobals.instance.isStaffSignedIn) {
                _showNetworkDialog();
              }
            }
          },
        ),
        BlocListener<ShopFrontConnectionBloc, ShopfrontConnectionStates>(
          listener: (context, state) {
            if (state is ConnectedToShopfront) {
              _attemptAutoAuthIfPossible();
            }
          },
        ),
        BlocListener<StaffAuthBloc, StaffAuthStates>(
          listener: (context, state) {
            if (state is StaffSignedOut ||
                state is StaffUnauthenticated ||
                state is StaffAuthError) {
              _promptStaffLoginIfNeeded(force: true);
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
                          mainAxisAlignment: isTablet
                              ? MainAxisAlignment.start
                              : MainAxisAlignment.center,
                          children: [
                            if (isTablet) const Spacer(),

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

                            if (isTablet) const Spacer(),

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
                                    StartSyncEvent(ipAddress: ""),
                                  );
                                  context.read<FetchCustomerBloc>().add(
                                    StartCustomerSyncEvent(ipAddress: ""),
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

                isTablet
                    ? GlassDrawer(
                        initialChildSize: drawerSizes.initialChildSize,
                        minChildSize: drawerSizes.minChildSize,
                        maxChildSize: drawerSizes.maxChildSize,
                      )
                    : const GlassDrawer(),
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
    // Scale logo for tablets based on screen size
    final double tabletScale = isTablet
        ? (media.size.shortestSide / 768).clamp(0.85, 1.3)
        : 1.0;
    final double horizontalPad = isTablet ? 40 : 25;
    final double logoHeight = isTablet ? (98 * tabletScale) : 75;
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
    final media = MediaQuery.of(context);
    final bool isTablet = media.size.shortestSide >= 600;
    // Scale text for tablets based on screen size
    final double tabletScale = isTablet
        ? (media.size.shortestSide / 768).clamp(0.85, 1.3)
        : 1.0;
    final double fontSize = isTablet ? (22 * tabletScale) : 22;

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
      child: Text(
        "Welcome to RM-Mobile",
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize),
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
            StartSyncEvent(ipAddress: ""),
          );
          context.read<FetchCustomerBloc>().add(
            StartCustomerSyncEvent(
              ipAddress: "",
            ),
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

class _DrawerSizes {
  const _DrawerSizes({
    required this.initialChildSize,
    required this.minChildSize,
    required this.maxChildSize,
  });

  final double initialChildSize;
  final double minChildSize;
  final double maxChildSize;
}