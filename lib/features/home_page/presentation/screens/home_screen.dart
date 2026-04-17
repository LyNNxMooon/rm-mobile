import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rmmobile/utils/navigation_extension.dart';
import 'package:rmmobile/utils/dependency_injection_utils.dart' as di;
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

import '../../../../constants/colors.dart';
import '../../../../constants/theme_colors.dart';
import '../../../../utils/global_var_utils.dart';
import '../../../../utils/log_utils.dart';
import '../../../../utils/responsive_utils.dart';

import '../../../customer_lookup/presentation/BLoC/customer_lookup_bloc.dart';
import '../../../customer_lookup/presentation/BLoC/customer_lookup_events.dart';
import '../../../loading_splash/presentation/BLoC/loading_splash_bloc.dart';
import '../../../loading_splash/presentation/BLoC/loading_splash_states.dart';
import '../../../stock_lookup/presentation/widgets/stock_request_error_dialog.dart';
import '../../../stocktake/presentation/screens/scanner_screen.dart';

import '../BLoC/home_screen_bloc.dart';
import '../BLoC/home_screen_events.dart';
import '../BLoC/home_screen_states.dart';
import '../BLoC/session_counts_cubit.dart';
import '../widgets/app_bar_session.dart';
import '../widgets/network_pc_dialog.dart';
import 'staff_login_screen.dart';

import '../widgets/glass_drawer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _autoAuthAttempted = false;
  bool _autoConnectAttempted = false;
  int? _savedPort;
  String _savedApiKey = "";
  String _savedShopfrontId = "";
  String _savedShopfrontName = "";
  String _savedStaffNo = "";
  String _savedStaffPassword = "";

  _DrawerSizes _resolveDrawerSizes(MediaQueryData media) {
    final bool isTablet = media.size.shortestSide >= Breakpoints.tablet;
    final bool isPortrait = media.orientation == Orientation.portrait;

    double initialChildSize;
    double minChildSize;
    double maxChildSize;

    if (isTablet) {
      if (isPortrait) {
        // Tablet portrait: drawer starts at 60% of screen height
        initialChildSize = 0.60;
        minChildSize = 0.58;
        maxChildSize = 0.91;
      } else {
        // Tablet landscape: drawer starts at 55% of screen height
        initialChildSize = 0.55;
        minChildSize = 0.53;
        maxChildSize = 0.90;
      }
    } else {
      // Phone - drawer takes 62% of screen from bottom (lowered to give more space for logo)
      if (isPortrait) {
        initialChildSize = 0.62;
        minChildSize = 0.62;
        maxChildSize = 0.88;
      } else {
        initialChildSize = 0.62;
        minChildSize = 0.60;
        maxChildSize = 0.86;
      }
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
    _requestSavedInfo();

    final currentParamState = context
        .read<NetworkSavedPathValidationBloc>()
        .state;

    if (currentParamState is ErrorFetchingSavedPaths ||
        currentParamState is ErrorCheckingConnection) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final hasSavedShopfront = (AppGlobals.instance.shopfront ?? "")
            .trim()
            .isNotEmpty;
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
  }

  void _requestSavedInfo() {
    context.read<StaffAuthBloc>().add(LoadConnectionInfoEvent());
    context.read<StaffAuthBloc>().add(LoadSavedStaffCredentialsEvent());
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
    final int? port = _savedPort;
    final String apiKey = _savedApiKey;
    final String shopfrontId = _savedShopfrontId;
    final String shopfrontName = _savedShopfrontName;
    final String staffNo = _savedStaffNo;
    final String staffPassword = _savedStaffPassword;
    final bool missingConnection = ip.isEmpty || port == null || apiKey.isEmpty;
    final bool missingShopfront =
        shopfrontId.trim().isEmpty || shopfrontName.trim().isEmpty;

    if (missingConnection || missingShopfront) {
      logger.d("Auto-auth skipped: missing connection/shopfront info.");
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
        shopfrontId: shopfrontId.trim(),
        shopfrontName: shopfrontName.trim(),
        staffNo: staffNo,
        password: staffPassword,
      ),
    );
  }

  Future<void> _attemptAutoShopfrontConnect() async {
    if (_autoConnectAttempted || !mounted) return;
    if (context.read<ShopFrontConnectionBloc>().state is ConnectedToShopfront) {
      return;
    }

    final savedIp = (AppGlobals.instance.currentHostIp ?? "").trim();
    final int? port = _savedPort;
    final String apiKey = _savedApiKey;
    final String shopfrontId = _savedShopfrontId;
    final String shopfrontName = _savedShopfrontName;
    final bool missingConnection =
        savedIp.isEmpty || port == null || apiKey.isEmpty;
    final bool missingShopfront =
        shopfrontId.trim().isEmpty || shopfrontName.trim().isEmpty;

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
        shopfrontId: shopfrontId.trim(),
        shopfrontName: shopfrontName.trim(),
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

  void _handleStocktakeTap() {
    if (context.read<FetchStockBloc>().state is FetchStockProgress) {
      showTopSnackBar(
        Overlay.of(context),
        const CustomSnackBar.info(
          message: "Stock sync in progress. Please wait.",
        ),
      );
      return;
    }

    if (!AppGlobals.instance.hasPermission("StockManagement_Stocktake")) {
      showTopSnackBar(
        Overlay.of(context),
        const CustomSnackBar.error(
          message: "You do not have permission to start stocktaking.",
        ),
      );
      return;
    }

    final currentState = context.read<FetchStockBloc>().state;

    if (currentState is! FetchStockProgress) {
      context.read<FetchStockBloc>().add(StartSyncEvent(ipAddress: ""));
      context.read<FetchCustomerBloc>().add(
        StartCustomerSyncEvent(ipAddress: ""),
      );
    }

    context.navigateToNext(const ScannerScreen());
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final bool isTablet = context.isTablet;
    final bool isPortrait = context.isPortrait;
    final drawerSizes = _resolveDrawerSizes(media);

    // Calculate available space between AppBarSession end and drawer top edge
    // SafeArea content height (screen height minus top safe padding)
    final double safeAreaContentHeight = media.size.height - media.padding.top;
    // Drawer top position from SafeArea top (drawer takes initialChildSize from bottom)
    final double drawerTopFromSafeTop =
        safeAreaContentHeight * (1.0 - drawerSizes.initialChildSize);
    // AppBarSession height
    const double appBarSessionHeight = 60.0;
    // Content area = space between AppBarSession bottom and drawer top edge
    final double contentAreaHeight = drawerTopFromSafeTop - appBarSessionHeight;

    return MultiBlocListener(
      listeners: [
        BlocListener<NetworkSavedPathValidationBloc, LoadingSplashStates>(
          listener: (context, state) {
            if (state is ConnectionValid) {
              _attemptAutoShopfrontConnect();
            }
            if (state is ErrorFetchingSavedPaths ||
                state is ErrorCheckingConnection) {
              final hasSavedShopfront = (AppGlobals.instance.shopfront ?? "")
                  .trim()
                  .isNotEmpty;
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
            if (state is StaffConnectionInfoLoaded) {
              _savedPort = state.port;
              _savedApiKey = state.apiKey;
              _savedShopfrontId = state.shopfrontId;
              _savedShopfrontName = state.shopfrontName;
              _attemptAutoShopfrontConnect();
            }
            if (state is StaffCredentialsLoaded) {
              _savedStaffNo = state.staffNo.trim();
              _savedStaffPassword = state.password.trim();
              _attemptAutoAuthIfPossible();
            }
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
          decoration: BoxDecoration(gradient: context.appColors.heroGradient),
          child: SafeArea(
            bottom: false,
            top: true,
            child: Stack(
              children: [
                Column(
                  children: [
                    // Extra top spacing for mobile only (above app bar)
                    if (!isTablet) const SizedBox(height: 8),
                    const AppBarSession(),
                    SizedBox(
                      height: contentAreaHeight,
                      child: SingleChildScrollView(
                        physics: const ClampingScrollPhysics(),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: contentAreaHeight,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Extra top spacing for mobile only
                              if (!isTablet) const SizedBox(height: 12),
                              logo(),
                              SizedBox(
                                height: isTablet ? (isPortrait ? 24 : 16) : 22,
                              ),
                              headerTitle(),
                              syncWatcher(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                BlocProvider(
                  create: (_) => di.sl<SessionCountsCubit>(),
                  child: GlassDrawer(
                    initialChildSize: drawerSizes.initialChildSize,
                    minChildSize: drawerSizes.minChildSize,
                    maxChildSize: drawerSizes.maxChildSize,
                    onStocktakeTap: _handleStocktakeTap,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget logo() {
    final media = MediaQuery.of(context);
    final bool isTablet = context.isTablet;
    final bool isLargeTablet = context.isLargeTablet;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final double tabletScale = isTablet
        ? (media.size.shortestSide / 768).clamp(0.85, 1.3)
        : 1.0;
    final double horizontalPad = isTablet ? 40 : 25;
    final double logoHeight = isLargeTablet
        ? (112 * tabletScale)
        : (isTablet ? (98 * tabletScale) : 75);
    final String logoAsset = isDark
        ? "assets/images/trademark_dark.png"
        : "assets/images/trademark.png";
    return Center(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: horizontalPad),
        width: double.infinity,
        height: logoHeight,
        child: Image.asset(logoAsset, fit: BoxFit.contain),
      ),
    );
  }

  Widget headerTitle() {
    final media = MediaQuery.of(context);
    final bool isTablet = context.isTablet;
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
          context.read<FetchStockBloc>().add(StartSyncEvent(ipAddress: ""));
          context.read<FetchCustomerBloc>().add(
            StartCustomerSyncEvent(ipAddress: ""),
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
