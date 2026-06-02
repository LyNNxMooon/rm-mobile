import 'dart:async';
//import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rmmobile/utils/navigation_extension.dart';
import 'package:rmmobile/utils/dependency_injection_utils.dart' as di;
import 'package:rmmobile/utils/adaptive_scaffold.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

import '../../../../constants/colors.dart';
import '../../../../constants/theme_colors.dart';
import '../../../../constants/txt_styles.dart';
import '../../../../utils/global_var_utils.dart';
import '../../../../utils/log_utils.dart';
import '../../../../utils/responsive_utils.dart';
import '../../../../utils/sync_utils.dart';
import '../../../../utils/route_observer.dart';
import '../../../../local_db/local_db_dao.dart';

import '../../../loading_splash/presentation/BLoC/loading_splash_bloc.dart';
import '../../../loading_splash/presentation/BLoC/loading_splash_states.dart';
import '../../../stock_lookup/presentation/widgets/stock_request_error_dialog.dart';
import '../../../stock_lookup/presentation/screens/stock_lookup_screen.dart';
import '../../../customer_lookup/presentation/screens/customer_lookup_screen.dart';
import '../../../customer_lookup/presentation/BLoC/customer_lookup_bloc.dart';
import '../../../customer_lookup/presentation/BLoC/customer_lookup_states.dart';
import '../../../stocktake/presentation/screens/scanner_screen.dart';
import '../../../transactions/presentation/BLoC/sales_bloc.dart';
import '../../../transactions/presentation/screens/sales_screen.dart';
import '../../domain/use_cases/discover_host.dart';

import '../BLoC/home_screen_bloc.dart';
import '../BLoC/home_screen_events.dart';
import '../BLoC/home_screen_states.dart';
import '../BLoC/session_counts_cubit.dart';
import '../BLoC/dashboard_style_cubit.dart';
import '../BLoC/font_size_cubit.dart';
import '../widgets/app_bar_session.dart';
import '../widgets/network_pc_dialog.dart';
import '../widgets/transaction_pulse_widget.dart';
import '../widgets/glass_drawer.dart';
import 'staff_login_screen.dart';
import 'settings_screen.dart';
import 'coming_soon_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with RouteAware {
  bool _autoAuthAttempted = false;
  bool _autoConnectAttempted = false;
  int? _savedPort;
  String _savedApiKey = "";
  String _savedShopfrontId = "";
  String _savedShopfrontName = "";
  String _savedStaffNo = "";
  String _savedStaffPassword = "";
  int _selectedTabIndex = 0;
  Timer? _sessionCountsTimer;
  late final SessionCountsCubit _sessionCountsCubit;

  @override
  void initState() {
    super.initState();

    context.read<SettingsBloc>().add(RunHistoryCleanupEvent());
    _requestSavedInfo();
    _sessionCountsCubit = di.sl<SessionCountsCubit>();
    _sessionCountsCubit.loadSessionCounts();
    _startSessionCountsRefresh();

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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void didPopNext() {
    _sessionCountsCubit.loadSessionCounts();
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _sessionCountsTimer?.cancel();
    _sessionCountsCubit.close();
    super.dispose();
  }

  void _startSessionCountsRefresh() {
    _sessionCountsTimer?.cancel();
    _sessionCountsTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (!mounted) return;
      _sessionCountsCubit.loadSessionCounts();
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

  void _showNetworkDialog({String? message}) {
    if (ModalRoute.of(context)?.isCurrent != true) return;
    if (context.read<FetchStockBloc>().state is FetchStockProgress) return;
    logger.d("State is noticed");
    context.read<FetchingNetworkServerBloc>().add(FetchNetworkServerEvent());
    showDialog(
      context: context,
      builder: (context) {
        return NetworkPcDialog(message: message);
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
    }

    context.navigateToNext(const ScannerScreen());
  }

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
  Widget build(BuildContext context) {
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
              // Don't redirect if shopfront dialog is handling the login flow
              if (!AppGlobals.instance.isShopfrontDialogOpen) {
                _promptStaffLoginIfNeeded(force: true);
              }
            }
          },
        ),
      ],
      child: BlocProvider.value(
        value: _sessionCountsCubit,
        child: BlocBuilder<DashboardStyleCubit, String>(
          builder: (context, dashboardStyle) {
            final bool isProStyle = dashboardStyle == "pro";
            
            // Use LayoutBuilder to determine if we should use desktop navigation
            return LayoutBuilder(
              builder: (context, constraints) {
                final bool useDesktopNav = context.useDesktopNav;
                
                if (isProStyle) {
                  // Pro style: use adaptive navigation (bottom nav on mobile, rail on desktop)
                  return _buildProStyleLayout(context, useDesktopNav);
                } else {
                  // Classic style: always use the GlassDrawer
                  return _buildClassicStyleLayout(context);
                }
              },
            );
          },
        ),
      ),
    );
  }

  /// Navigation items for the adaptive scaffold (main navigation tabs)
  static const List<AdaptiveNavItem> _navigationItems = [
    AdaptiveNavItem(icon: Icons.home_rounded, label: "Home"),
    AdaptiveNavItem(icon: Icons.point_of_sale_outlined, label: "Transaction"),
    AdaptiveNavItem(icon: Icons.inventory_2_outlined, label: "Stock"),
    AdaptiveNavItem(icon: Icons.people_outline, label: "Customers"),
    AdaptiveNavItem(icon: Icons.more_horiz, label: "More"),
  ];

  /// Desktop-specific navigation items (includes Connect to server and Settings)
  static const List<AdaptiveNavItem> _desktopNavigationItems = [
    AdaptiveNavItem(icon: Icons.home_rounded, label: "Home"),
    AdaptiveNavItem(icon: Icons.point_of_sale_outlined, label: "Transaction"),
    AdaptiveNavItem(icon: Icons.inventory_2_outlined, label: "Stock"),
    AdaptiveNavItem(icon: Icons.people_outline, label: "Customers"),
    AdaptiveNavItem(icon: Icons.more_horiz, label: "More"),
  ];

  /// Builds the Pro style layout with adaptive navigation
  Widget _buildProStyleLayout(BuildContext context, bool useDesktopNav) {
    final colors = context.appColors;
    final bool isTablet = context.isTablet;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    // Desktop layout: NavigationRail on left + content
    if (useDesktopNav) {
      return Scaffold(
        backgroundColor: kPrimaryColor,
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            color: Color.fromRGBO(28, 57, 83, 1),
          ),
          child: Row(
            children: [
              // Navigation Rail with extended labels
              _buildNavigationRail(context, colors, isDark),
              // Main content area with 50px padding around white container
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(50.0),
                  child: Stack(
                    children: [
                      _buildHomeBody(context, useDesktopNav: true),
                      syncWatcher(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Tablet layout: NavigationRail on left + content (no bottom nav)
    if (isTablet) {
      return Scaffold(
        backgroundColor: kPrimaryColor,
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            color: Color.fromRGBO(28, 57, 83, 1),
          ),
          child: SafeArea(
            child: Row(
              children: [
                // Compact Navigation Rail for tablets
                _buildTabletNavigationRail(context, colors, isDark),
                // Main content area
                Expanded(
                  child: Stack(
                    children: [
                      Column(
                        children: [
                          const SizedBox(height: 8),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 64),
                            child: AppBarSession(),
                          ),
                          Expanded(child: _buildHomeBody(context, useDesktopNav: false, isTabletWithRail: true)),
                        ],
                      ),
                      syncWatcher(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Phone layout: content + BottomNavigationBar
    return Scaffold(
      extendBody: true,
      backgroundColor: kPrimaryColor,
      bottomNavigationBar: _buildBottomNav(context),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: Color.fromRGBO(28, 57, 83, 1),
        ),
        child: SafeArea(
          bottom: false,
          top: true,
          child: Stack(
            children: [
              Column(
                children: [
                  const SizedBox(height: 8),
                  const AppBarSession(),
                  Expanded(child: _buildHomeBody(context, useDesktopNav: false)),
                ],
              ),
              syncWatcher(),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds a compact NavigationRail for tablet layout (icons only, no extended labels)
  Widget _buildTabletNavigationRail(
    BuildContext context,
    AppThemeColors colors,
    bool isDark,
  ) {
    return Container(
      width: 90,
      color: const Color.fromRGBO(109, 205, 251, 1), // Same as bottom nav bar
      child: Column(
        children: [
          // App icon at the top - fills the nav bar width edge to edge
          Image.asset(
            "assets/images/appicon.png",
            width: 90,
            height: 110,
            fit: BoxFit.cover,
          ),
          // Navigation items
          Expanded(
            child: NavigationRail(
              selectedIndex: _selectedTabIndex,
              onDestinationSelected: (index) => setState(() => _selectedTabIndex = index),
              extended: false,
              minWidth: 90,
              groupAlignment: -0.4, // Slightly above center
              backgroundColor: Colors.transparent,
              selectedIconTheme: const IconThemeData(color: Colors.white, size: 24),
              unselectedIconTheme: const IconThemeData(color: Colors.white70, size: 24),
              indicatorColor: Colors.white.withOpacity(0.2),
              labelType: NavigationRailLabelType.selected,
              selectedLabelTextStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
                fontSize: 11,
              ),
              destinations: const [
                NavigationRailDestination(
                  icon: Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Icon(Icons.home_rounded)),
                  selectedIcon: Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Icon(Icons.home_rounded)),
                  label: Text("Home"),
                ),
                NavigationRailDestination(
                  icon: Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Icon(Icons.point_of_sale_outlined)),
                  selectedIcon: Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Icon(Icons.point_of_sale_outlined)),
                  label: Text("Transaction"),
                ),
                NavigationRailDestination(
                  icon: Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Icon(Icons.inventory_2_outlined)),
                  selectedIcon: Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Icon(Icons.inventory_2_outlined)),
                  label: Text("Stock"),
                ),
                NavigationRailDestination(
                  icon: Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Icon(Icons.people_outline)),
                  selectedIcon: Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Icon(Icons.people_outline)),
                  label: Text("Customers"),
                ),
                NavigationRailDestination(
                  icon: Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Icon(Icons.more_horiz)),
                  selectedIcon: Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Icon(Icons.more_horiz)),
                  label: Text("More"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the NavigationRail for desktop layout
  Widget _buildNavigationRail(
    BuildContext context,
    AppThemeColors colors,
    bool isDark,
  ) {
    return Container(
      color: isDark ? colors.surface : Colors.white,
      child: Column(
        children: [
          // Logo header - top padding aligns with shopfront name in main content
          Container(
            width: 220,
            padding: const EdgeInsets.fromLTRB(16, 72, 16, 16),
            child: Image.asset(
              "assets/images/trademark_dark.png",
              height: 32,
              fit: BoxFit.contain,
            ),
          ),
          const Divider(height: 1),
          // Navigation items
          Expanded(
            child: NavigationRail(
              selectedIndex: _selectedTabIndex,
              onDestinationSelected: (index) => setState(() => _selectedTabIndex = index),
              extended: true,
              minExtendedWidth: 220,
              backgroundColor: Colors.transparent,
              selectedIconTheme: const IconThemeData(color: kPrimaryColor, size: 22),
                  unselectedIconTheme: IconThemeData(color: colors.onSurfaceMuted, size: 22),
                  selectedLabelTextStyle: const TextStyle(
                    color: kPrimaryColor,
                    fontWeight: FontWeight.w400,
                    fontSize: 14,
                  ),
                  unselectedLabelTextStyle: TextStyle(
                    color: colors.onSurfaceMuted,
                    fontSize: 14,
                  ),
                  indicatorColor: kPrimaryColor.withOpacity(0.12),
                  destinations: _desktopNavigationItems
                      .map(
                        (item) => NavigationRailDestination(
                          icon: Icon(item.icon),
                          selectedIcon: Icon(item.icon),
                          label: Text(item.label),
                        ),
                      )
                      .toList(),
                ),
              ),
              // Bottom actions
              const Divider(height: 1),
              _buildRailAction(
                context,
                icon: Icons.laptop_mac_sharp,
                label: "Connect Server",
                colors: colors,
                isDark: isDark,
                onTap: () {
                  if (_isSyncInProgress(context)) {
                    showTopSnackBar(
                      Overlay.of(context),
                      const CustomSnackBar.info(message: "Sync in progress. Please wait."),
                    );
                    return;
                  }
                  context.read<FetchingNetworkServerBloc>().add(FetchNetworkServerEvent());
                  showDialog(
                    context: context,
                    builder: (context) => const NetworkPcDialog(),
                  );
                },
              ),
              _buildRailAction(
                context,
                icon: Icons.settings_outlined,
                label: "Settings",
                colors: colors,
                isDark: isDark,
                onTap: () => context.navigateToNext(const SettingsScreen()),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
  }

  /// Builds a custom action button for the NavigationRail trailing area
  Widget _buildRailAction(
    BuildContext context, {
    required IconData icon,
    required String label,
    required AppThemeColors colors,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 220,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(icon, size: 22, color: colors.onSurfaceMuted),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white70 : colors.onSurface,
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

  /// Builds the Classic style layout with GlassDrawer (mobile only pattern)
  Widget _buildClassicStyleLayout(BuildContext context) {
    //final colors = context.appColors;
    final bool isTablet = context.isTablet;
    final bool isPortrait = context.isPortrait;
    final media = MediaQuery.of(context);
    final drawerSizes = _resolveDrawerSizes(media);

    // Calculate available space between AppBarSession end and drawer top edge
    final double safeAreaContentHeight = media.size.height - media.padding.top;
    final double drawerTopFromSafeTop =
        safeAreaContentHeight * (1.0 - drawerSizes.initialChildSize);
    const double appBarSessionHeight = 60.0;
    final double contentAreaHeight = drawerTopFromSafeTop - appBarSessionHeight;

    return Scaffold(
      extendBody: true,
      backgroundColor: kPrimaryColor,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: Color.fromRGBO(28, 57, 83, 1),
        ),
        child: SafeArea(
          bottom: false,
          top: true,
          child: Stack(
            children: [
              Column(
                children: [
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
                            if (!isTablet) const SizedBox(height: 12),
                            _buildClassicLogo(context),
                            SizedBox(
                              height: isTablet ? (isPortrait ? 24 : 16) : 22,
                            ),
                            _buildClassicHeaderTitle(context),
                            syncWatcher(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              GlassDrawer(
                initialChildSize: drawerSizes.initialChildSize,
                minChildSize: drawerSizes.minChildSize,
                maxChildSize: drawerSizes.maxChildSize,
                onStocktakeTap: _handleStocktakeTap,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the logo for Classic style
  Widget _buildClassicLogo(BuildContext context) {
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

  /// Builds the header title for Classic style
  Widget _buildClassicHeaderTitle(BuildContext context) {
    final media = MediaQuery.of(context);
    final bool isTablet = context.isTablet;
    final double tabletScale = isTablet
        ? (media.size.shortestSide / 768).clamp(0.85, 1.3)
        : 1.0;
    final double fontSize = isTablet ? (22 * tabletScale) : 24;

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
        style: TextStyle(fontWeight: FontWeight.w500, fontSize: fontSize),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildHomeBody(BuildContext context, {bool useDesktopNav = false, bool isTabletWithRail = false}) {
    final colors = context.appColors;
    final bool isTablet = context.isTablet;
    final items = _filteredItemsForTab();

    // Separate regular items from coming soon items on home tab
    final bool isHomeTab = _selectedTabIndex == 0;
    final regularItems = isHomeTab
        ? items.where((item) => item['comingSoon'] != true).toList()
        : items;
    final comingSoonItems = isHomeTab
        ? items.where((item) => item['comingSoon'] == true).toList()
        : <Map<String, dynamic>>[];

    // Build the main content
    Widget content = Container(
      width: double.infinity,
      height: double.infinity,
      margin: useDesktopNav 
          ? EdgeInsets.zero  // Padding handles the gap on desktop
          : const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: Color.fromRGBO(13, 27, 52, 1),
        // On desktop: rounded corners on all sides; on mobile: no rounding
        borderRadius: useDesktopNav
            ? BorderRadius.circular(10)
            : BorderRadius.zero,
        boxShadow: [
          BoxShadow(
            color: colors.cardShadow,
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: useDesktopNav
            ? BorderRadius.circular(10)
            : BorderRadius.zero,
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            // Less bottom padding on desktop/tablet with rail (no bottom nav)
            bottom: (useDesktopNav || isTabletWithRail) ? 24 : 80 + MediaQuery.of(context).padding.bottom,
            // Horizontal padding for tablet layout
            left: isTabletWithRail ? 64 : 0,
            right: isTabletWithRail ? 64 : 0,
          ),
          physics: const ClampingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            _buildGreetingHeader(context),
            if (isHomeTab)
              TransactionPulseWidget(
                onInvoiceTap: () => _handleActionTap('account_sales'),
                onSalesOrderTap: () => _handleActionTap('sales_order'),
                onQuoteTap: () => _handleActionTap('quotes'),
                onLaybyTap: () => _handleActionTap('lay_bys'),
              ),
            _buildSectionHeader(
              _tabTitleForIndex(_selectedTabIndex),
              context,
              icon: _tabIconForIndex(_selectedTabIndex),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _buildActionGrid(
                context,
                regularItems,
                key: ValueKey(_selectedTabIndex),
                useDesktopNav: useDesktopNav,
              ),
            ),
            if (isHomeTab && comingSoonItems.isNotEmpty) ...[
              _buildSectionHeader(
                "Information",
                context,
                icon: Icons.info_outline_rounded,
              ),
              _buildInformationGrid(
                context,
                comingSoonItems,
                useDesktopNav: useDesktopNav,
              ),
            ],
            if (isTablet) const SizedBox(height: 6),
          ],
        ),
      ),
      ),
    );

    return content;
  }

  Widget _buildGreetingHeader(BuildContext context) {
   // final colors = context.appColors;
    final bool isTablet = context.isTablet;
    final String shopfront = (AppGlobals.instance.shopfront ?? "").trim();
    final String shopName = shopfront.isEmpty
        ? "Your shopfront"
        : shopfront.split(r'\\').last;
    final String staffName = (AppGlobals.instance.staffName ?? "").trim();
    final String staffLabel = staffName.isEmpty
        ? "Staff: Not signed in"
        : "Staff: $staffName";

    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          isTablet ? 22 : 16,
          isTablet ? 22 : 16,
          isTablet ? 22 : 16,
          8,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              shopName,
              style: getSmartTitle(
                fontSize: isTablet ? 20 : 18,
                color: Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Text(
              staffLabel,
              style: TextStyle(
                color: Colors.white60,
                fontSize: isTablet ? 14 : 13,
                fontWeight: FontWeight.w400,
              ),
            ),
            SizedBox(height: isTablet ? 14 : 10),
            _buildStatusRow(context),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(BuildContext context) {
    final bool isTablet = context.isTablet;
    return BlocBuilder<FetchStockBloc, FetchStockStates>(
      builder: (context, _) {
        return BlocBuilder<FetchCustomerBloc, FetchCustomerStates>(
          builder: (context, _) {
            final bool isSyncing = _isSyncInProgress(context);
            return Wrap(
              spacing: isTablet ? 10 : 6,
              runSpacing: isTablet ? 10 : 6,
              children: [
                _buildStatusPill(
                  context,
                  label: isSyncing ? "Syncing" : "Sync complete",
                  icon: isSyncing ? Icons.sync : Icons.check_circle_outline,
                  color: isSyncing ? Colors.orange : Colors.green,
                ),
                FutureBuilder<String>(
                  future: _loadLastSyncLabel(),
                  builder: (context, snapshot) {
                    final label = snapshot.data ?? "Last sync: --";
                    return _buildStatusPill(
                      context,
                      label: label,
                      icon: Icons.schedule,
                      color: kSecondaryColor,
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildStatusPill(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color color,
  }) {
    //final colors = context.appColors;
    final bool isTablet = context.isTablet;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 14 : 10,
        vertical: isTablet ? 8 : 5,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border(
          top: BorderSide(color: const Color.fromRGBO(109, 205, 251, 1).withOpacity(0.5), width: 1),
          left: BorderSide(color: const Color.fromRGBO(109, 205, 251, 1).withOpacity(0.5), width: 1),
          right: BorderSide(color: const Color.fromRGBO(109, 205, 251, 1).withOpacity(0.5), width: 0.42),
          bottom: BorderSide(color: const Color.fromRGBO(109, 205, 251, 1).withOpacity(0.5), width: 0.42),
        ),
        color: const Color.fromRGBO(28, 57, 83, 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: isTablet ? 16 : 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: isTablet ? 13 : 12,
              fontWeight: FontWeight.w400,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    String title,
    BuildContext context, {
    bool compact = false,
    IconData? icon,
  }) {
    //final colors = context.appColors;
    final bool isTablet = context.isTablet;
    final EdgeInsets padding = compact
        ? EdgeInsets.symmetric(horizontal: isTablet ? 22 : 16)
        : EdgeInsets.fromLTRB(
            isTablet ? 22 : 16,
            isTablet ? 30 : 20,
            isTablet ? 22 : 16,
            12,
          );
    return Padding(
      padding: padding,
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: isTablet ? 20 : 18,
              color: Colors.white70,
            ),
            const SizedBox(width: 8),
          ],
          Text(
            title,
            style: getSmartTitle(
              fontSize: isTablet ? 18 : 18,
              color: Colors.white,
            ).copyWith(height: compact ? 1.0 : null),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              height: 0.8,
              color: Colors.white30,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionGrid(
    BuildContext context,
    List<Map<String, dynamic>> items, {
    Key? key,
    bool compact = false,
    bool useDesktopNav = false,
  }) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    // On desktop, use constrained max width for calculations
    final double effectiveWidth = useDesktopNav
        ? screenWidth.clamp(0, Breakpoints.maxContentWidth)
        : screenWidth;
    final bool isLargeFont = context.read<FontSizeCubit>().isLarge;
    final bool isTablet = effectiveWidth >= 600;
    // Detect compact tablet (small height in landscape or smaller tablets)
    final bool isCompactTablet = isTablet && screenHeight < 700;

    // Strict Responsive Rules: Tablet/Desktop (>= 600) gets 4 cols, Mobile (< 600) gets 2 cols.
    final int crossAxisCount = isTablet ? 4 : 2;

    final double spacing = isTablet ? 24 : 20;
    final double mainSpacing = compact ? 0 : (isTablet ? 24 : 20);
    final double horizontalPadding = isTablet ? 22 : 16;
    // Square-ish tiles for the new Transaction-card look.
    // Use wider aspect ratio on compact tablets to reduce height
    final double childAspectRatio = isCompactTablet 
        ? 1.25 
        : (isTablet ? 1.15 : (isLargeFont ? 0.85 : 0.95));

    return Padding(
      key: key,
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: BlocBuilder<SessionCountsCubit, SessionCountsState>(
        builder: (context, sessionState) {
          return GridView.builder(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: spacing,
              mainAxisSpacing: mainSpacing,
              childAspectRatio: childAspectRatio,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              // Wire up the badge count dynamically
              int badgeCount = _badgeCountForAction(item['action'] as String?, sessionState.counts);
              return _buildActionTile(context, item, badgeCount: badgeCount);
            },
          );
        },
      ),
    );
  }

  Widget _buildInformationGrid(
    BuildContext context,
    List<Map<String, dynamic>> items, {
    bool useDesktopNav = false,
  }) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    final double effectiveWidth = useDesktopNav
        ? screenWidth.clamp(0, Breakpoints.maxContentWidth)
        : screenWidth;
    final bool isLargeFont = context.read<FontSizeCubit>().isLarge;
    final bool isTablet = effectiveWidth >= 600;
    // Detect compact tablet (small height in landscape or smaller tablets)
    final bool isCompactTablet = isTablet && screenHeight < 700;

    // Match action grid: Tablet/Desktop (>= 600) gets 3 cols, Mobile (< 600) gets 1 col.
    final int crossAxisCount = isTablet ? 3 : 1;
    // Match action card aspect ratio for phones to prevent overflow
    final double childAspectRatio = isCompactTablet 
        ? 1.8 
        : (isTablet ? 1.7 : (isLargeFont ? 1.9 : 2.1));
    final double spacing = isTablet ? 24 : 20;
    final double horizontalPadding = isTablet ? 22 : 16;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: GridView.builder(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: spacing,
          mainAxisSpacing: spacing,
          childAspectRatio: childAspectRatio,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) =>
            _buildInformationTile(context, items[index]),
      ),
    );
  }



Widget _buildActionTile(
  BuildContext context,
  Map<String, dynamic> item, {
  int badgeCount = 0,
}) {
  final bool isTablet = MediaQuery.of(context).size.width > 600;
  final Color itemColor = item['color'] ?? const Color(0xFF0078D4);

  return Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: () {
        _handleActionTap(item['action'] as String?);
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          // 1. The Border: Thicker on top/left, thinner on right/bottom
          border: Border(
            top: BorderSide(color: Colors.white.withOpacity(0.12), width: 1.5),
            left: BorderSide(color: Colors.white.withOpacity(0.12), width: 1.5),
            right: BorderSide(color: Colors.white.withOpacity(0.12), width: 0.42),
            bottom: BorderSide(color: Colors.white.withOpacity(0.12), width: 0.42),
          ),
          // 2. The Glass Sweep: More blue, slightly brighter
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF42A5F5).withOpacity(0.40), // Deeper blue with more saturation
              Colors.transparent,                        // Blends smoothly into background
            ],
            stops: const [0.0, 0.6], // Smooth fade out across the card
          ),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? 16 : 12,
            vertical: isTablet ? 26 : 24,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              
              // 3. The Icon (Standard physical drop shadow only)
              Container(
                width: isTablet ? 70 : 52,
                height: isTablet ? 70 : 52,
                decoration: BoxDecoration(
                  color: itemColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  item['icon'] as IconData?,
                  color: Colors.white,
                  size: isTablet ? 38 : 28,
                ),
              ),

              SizedBox(height: isTablet ? 20 : 12),

              // Title Text
              Flexible(
                child: Text(
                  item['title'] as String? ?? '',
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style:  TextStyle(
                    color: Colors.white,
                    fontSize: isTablet ? 18 : 16,
                    //fontWeight: FontWeight.w500,
                    letterSpacing: 0.2,
                  ),
                ),
              ),

              const SizedBox(height: 6),

              // Subtitle Text
              Text(
                item['subTitle'] as String? ?? '',
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:  TextStyle(
                  color: Color(0xFF7A8B9E), // Muted grey-blue
                  fontSize: isTablet ? 14 : 13,
                  fontWeight: FontWeight.w400,
                ),
              ),

              SizedBox(height: isTablet ? 28 : 12),

              // 4. The Underline: Visible and centered
              Container(
                height: 1,
                width: 200, 
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.white.withOpacity(0.20), // Visible peak in the center
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.5, 1.0],
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

Widget _buildInformationTile(
  BuildContext context,
  Map<String, dynamic> item, {
  int badgeCount = 0,
}) {
  final bool isTablet = MediaQuery.of(context).size.width > 600;
  
  // Use the same color as the app bar / main background
  final Color cardColor = const Color.fromRGBO(28, 57, 83, 1);

  return Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: () {
        _handleActionTap(item['action'] as String?);
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          // 1. The Border: Blue color
          border: Border(
            top: BorderSide(color: const Color.fromRGBO(109, 205, 251, 1).withOpacity(0.5), width: 1),
            left: BorderSide(color: const Color.fromRGBO(109, 205, 251, 1).withOpacity(0.5), width: 1),
            right: BorderSide(color: const Color.fromRGBO(109, 205, 251, 1).withOpacity(0.5), width: 0.42),
            bottom: BorderSide(color: const Color.fromRGBO(109, 205, 251, 1).withOpacity(0.5), width: 0.42),
          ),
          // 2. The Solid Background
          color: cardColor,
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? 16 : 12,
            vertical: isTablet ? 26 : 12,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              
              // 3. The Icon: White background, dirty green icon
              Container(
                width: isTablet ? 70 : 52,
                height: isTablet ? 70 : 52,
                decoration: BoxDecoration(
                  color: Colors.white, // Solid white background
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  item['icon'] as IconData?,
                  color: cardColor, // Icon matches the card's background color
                  size: isTablet ? 38 : 28,
                ),
              ),

              const SizedBox(height: 20),

              // Title Text (Kept styling exactly as provided)
              Flexible(
                child: Text(
                  item['title'] as String? ?? '',
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isTablet ? 18 : 16,
                    letterSpacing: 0.2,
                  ),
                ),
              ),

              const SizedBox(height: 6),

              // Subtitle Text (Kept styling exactly as provided)
              Text(
                item['subTitle'] as String? ?? '',
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Color(0xFF7A8B9E), // Muted grey-blue
                  fontSize: isTablet ? 14 : 13,
                  fontWeight: FontWeight.w400,
                ),
              ),

              SizedBox(height: isTablet ? 16 : 12),

              // 4. The Underline: Visible and centered (Kept exactly as provided)
              Container(
                height: 1,
                width: 200, 
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.white.withOpacity(0.20), // Visible peak in the center
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.5, 1.0],
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

  Widget _buildBottomNav(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: _selectedTabIndex,
      type: BottomNavigationBarType.fixed,
      backgroundColor: Color.fromRGBO(109, 205, 251, 1),
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.white70,
      onTap: (index) => setState(() => _selectedTabIndex = index),
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: "Home"),
        BottomNavigationBarItem(
          icon: Icon(Icons.point_of_sale_outlined),
          label: "Transaction",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.inventory_2_outlined),
          label: "Stock Management",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.people_outline),
          label: "Customers",
        ),
        BottomNavigationBarItem(icon: Icon(Icons.more_horiz), label: "More"),
      ],
    );
  }

  String _tabTitleForIndex(int index) {
    switch (index) {
      case 1:
        return "Transaction";
      case 2:
        return "Stock Management";
      case 3:
        return "Customers";
      case 4:
        return "More";
      default:
        return "Transaction";
    }
  }

  IconData _tabIconForIndex(int index) {
    switch (index) {
      case 1:
        return Icons.point_of_sale_outlined;
      case 2:
        return Icons.inventory_2_outlined;
      case 3:
        return Icons.people_outline;
      case 4:
        return Icons.more_horiz;
      default:
        return Icons.apps_rounded;
    }
  }

  bool _isSyncInProgress(BuildContext context) {
    return context.read<FetchStockBloc>().state is FetchStockProgress ||
        context.read<FetchCustomerBloc>().state is FetchCustomerProgress;
  }

  bool _blockTransactionsIfSyncing(BuildContext context) {
    if (!_isSyncInProgress(context)) return false;
    showTopSnackBar(
      Overlay.of(context),
      const CustomSnackBar.info(message: "Sync in progress. Please wait."),
    );
    return true;
  }

  /// Checks host connection in background before navigating to a screen.
  /// If connection fails, shows the network PC dialog with an error message.
  /// Returns true if connection succeeded, false otherwise.
  Future<bool> _checkHostConnection() async {
    final ip = (AppGlobals.instance.currentHostIp ?? "").trim();
    final portStr = await LocalDbDAO.instance.getHostPort();
    final port = int.tryParse(portStr ?? "") ?? 5000;

    if (ip.isEmpty) {
      _showNetworkDialog(
        message: "The server connection info has changed! Please connect to server again.",
      );
      return false;
    }

    try {
      final discoverHost = di.sl<DiscoverHost>();
      await discoverHost(ip, port);
      return true;
    } catch (e) {
      logger.d("Host connection check failed: $e");
      if (mounted) {
        _showNetworkDialog(
          message: "The server connection info has changed! Please connect to server again.",
        );
      }
      return false;
    }
  }

  /// Navigates to a transaction screen immediately.
  /// Connection check is performed inside SalesScreen itself.
  void _navigateToTransactionScreen({
    required String title,
    required Color themeColor,
    required IconData icon,
  }) {
    context
        .navigateToNext(
          BlocProvider(
            create: (_) => di.sl<SalesBloc>(),
            child: SalesScreen(
              title: title,
              themeColor: themeColor,
              icon: icon,
            ),
          ),
        )
        .then((_) => _sessionCountsCubit.loadSessionCounts());
  }

  /// Checks host connection silently without showing dialog on failure.
  /// Returns true if connection succeeded, false otherwise.
  Future<bool> _checkHostConnectionSilent() async {
    final ip = (AppGlobals.instance.currentHostIp ?? "").trim();
    final portStr = await LocalDbDAO.instance.getHostPort();
    final port = int.tryParse(portStr ?? "") ?? 5000;

    if (ip.isEmpty) {
      return false;
    }

    try {
      final discoverHost = di.sl<DiscoverHost>();
      await discoverHost(ip, port);
      return true;
    } catch (e) {
      logger.d("Host connection check failed: $e");
      return false;
    }
  }

  Future<String> _loadLastSyncLabel() async {
    try {
      final String? shopfrontId = await LocalDbDAO.instance.getShopfrontId();
      if (shopfrontId == null || shopfrontId.trim().isEmpty) {
        return "Last sync: --";
      }

      final String stockKey = 'stock_sync_timestamp_$shopfrontId';
      final String customerKey = 'customer_sync_timestamp_$shopfrontId';
      final String? stockValue = await LocalDbDAO.instance.getAppConfig(
        stockKey,
      );
      final String? customerValue = await LocalDbDAO.instance.getAppConfig(
        customerKey,
      );

      final DateTime? latest = _latestSyncTimestamp(stockValue, customerValue);

      if (latest == null) {
        return "Last sync: --";
      }

      return "Last sync: ${_formatRelativeTime(latest)}";
    } catch (_) {
      return "Last sync: --";
    }
  }

  DateTime? _latestSyncTimestamp(String? stockValue, String? customerValue) {
    DateTime? stockTime;
    DateTime? customerTime;

    if (stockValue != null && stockValue.trim().isNotEmpty) {
      stockTime = DateTime.tryParse(stockValue.trim());
    }
    if (customerValue != null && customerValue.trim().isNotEmpty) {
      customerTime = DateTime.tryParse(customerValue.trim());
    }

    if (stockTime == null && customerTime == null) return null;
    if (stockTime == null) return customerTime;
    if (customerTime == null) return stockTime;

    return stockTime.isAfter(customerTime) ? stockTime : customerTime;
  }

  String _formatRelativeTime(DateTime timestamp) {
    final Duration diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes < 1) return "just now";
    if (diff.inMinutes < 60) return "${diff.inMinutes} min ago";
    if (diff.inHours < 24) return "${diff.inHours} hr ago";
    if (diff.inDays < 7) {
      return "${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago";
    }
    final int weeks = (diff.inDays / 7).floor();
    if (weeks < 5) return "$weeks wk${weeks == 1 ? '' : 's'} ago";
    final int months = (diff.inDays / 30).floor();
    if (months < 12) return "$months mo ago";
    final int years = (diff.inDays / 365).floor();
    return "$years yr${years == 1 ? '' : 's'} ago";
  }

  int _badgeCountForAction(String? action, Map<String, int> sessionCounts) {
    if (action == null) return 0;
    String? sessionType;
    switch (action) {
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
    return sessionType != null ? (sessionCounts[sessionType] ?? 0) : 0;
  }

  List<Map<String, dynamic>> _filteredItemsForTab() {
    if (_selectedTabIndex == 0) return _actionItems;
    if (_selectedTabIndex == 4) {
      return _actionItems
          .where(
            (item) =>
                (item['category'] == 'more') || (item['comingSoon'] == true),
          )
          .toList();
    }
    final String category = switch (_selectedTabIndex) {
      1 => 'sales',
      2 => 'stock',
      3 => 'customers',
      _ => 'all',
    };
    return _actionItems.where((item) => item['category'] == category).toList();
  }

  void _handleActionTap(String? action) {
    if (action == null) return;
    if (action == "stocktake") {
      _handleStocktakeTap();
      return;
    }
    if (action == "stock_lookup") {
      if (!AppGlobals.instance.hasAnyPermission(const <String>[
        "Information_Stock",
      ])) {
        showTopSnackBar(
          Overlay.of(context),
          const CustomSnackBar.error(
            message: "You do not have permission to access Stock Lookup.",
          ),
        );
        return;
      }
      context.navigateToNext(const StockLookupScreen());
      return;
    }
    if (action == "customer_lookup") {
      if (!AppGlobals.instance.hasAnyPermission(const <String>[
        "Information_Customer",
      ])) {
        showTopSnackBar(
          Overlay.of(context),
          const CustomSnackBar.error(
            message: "You do not have permission to access Customer Lookup.",
          ),
        );
        return;
      }
      context.navigateToNext(const CustomerLookupScreen());
      return;
    }
    if (action == "settings") {
      context.navigateToNext(const SettingsScreen());
      return;
    }

    if (action == "sales") {
      if (_blockTransactionsIfSyncing(context)) return;
      _navigateToTransactionScreen(
        title: "Sales",
        themeColor: Colors.green,
        icon: Icons.point_of_sale_outlined,
      );
      return;
    }
    if (action == "account_sales") {
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
      _navigateToTransactionScreen(
        title: "Account Sales",
        themeColor: const Color.fromARGB(255, 210, 148, 172),
        icon: Icons.receipt_long_outlined,
      );
      return;
    }
    if (action == "sales_order") {
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
      _navigateToTransactionScreen(
        title: "Sales Order",
        themeColor: const Color.fromARGB(255, 44, 133, 211),
        icon: Icons.shopping_cart_outlined,
      );
      return;
    }
    if (action == "quotes") {
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
      _navigateToTransactionScreen(
        title: "Quotes",
        themeColor: Colors.orange,
        icon: Icons.request_quote_outlined,
      );
      return;
    }
    if (action == "lay_bys") {
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
      _navigateToTransactionScreen(
        title: "Lay-bys",
        themeColor: const Color.fromARGB(255, 152, 86, 165),
        icon: Icons.inventory_2_outlined,
      );
      return;
    }

    context.navigateToNext(const ComingSoonScreen());
  }

  final List<Map<String, dynamic>> _actionItems = [
    {
      "title": "Account Sales",
      "subTitle": "Invoice Customers",
      "icon": Icons.contact_page_outlined,
      "color": const Color(0xFF0F52BA),
      "comingSoon": false,
      "action": "account_sales",
      "category": "sales",
    },
    {
      "title": "Sales Order",
      "subTitle": "Create orders",
      "icon": Icons.shopping_cart_outlined,
      "color": const Color(0xFF00C4CC),
      "comingSoon": false,
      "action": "sales_order",
      "category": "sales",
    },
    {
      "title": "Quotes",
      "subTitle": "Issue Estimates",
      "icon": Icons.edit_document,
      "color": const Color(0xFF007AFF),
      "comingSoon": false,
      "action": "quotes",
      "category": "sales",
    },
    {
      "title": "Lay-bys",
      "subTitle": "Manage Lay-bys",
      "icon": Icons.folder_open_rounded,
      "color": const Color(0xFF788A9F),
      "comingSoon": false,
      "action": "lay_bys",
      "category": "sales",
    },
    {
      "title": "Stock Lookup",
      "subTitle": "Search inventory",
      "icon": Icons.inventory_2_outlined,
      "color": kPrimaryColor,
      "comingSoon": false,
      "action": "stock_lookup",
      "category": "stock",
    },
    {
      "title": "Stocktake",
      "subTitle": "Count inventory",
      "icon": Icons.fact_check_outlined,
      "color": Colors.teal,
      "comingSoon": false,
      "action": "stocktake",
      "category": "stock",
    },
    {
      "title": "Customers",
      "subTitle": "Search customers",
      "icon": Icons.people_outline,
      "color": kPrimaryColor,
      "comingSoon": false,
      "action": "customer_lookup",
      "category": "customers",
    },
    // Coming Soon items (show on Home and More only)
    {
      "title": "Sales",
      "subTitle": "Coming Soon",
      "icon": Icons.insights_outlined,
      "color": const Color(0xFF00C896),
      "comingSoon": true,
      "action": "sales",
      "category": "more",
    },
    {
      "title": "Goods Received",
      "subTitle": "Coming Soon",
      "icon": Icons.work_outline,
      "color": const Color(0xFF4DB6AC),
      "comingSoon": true,
      "action": "coming_soon",
      "category": "more",
    },
    {
      "title": "Purchase Orders",
      "subTitle": "Coming Soon",
      "icon": Icons.local_offer_outlined,
      "color": const Color(0xFF5C6BC0),
      "comingSoon": true,
      "action": "coming_soon",
      "category": "more",
    },
    {
      "title": "Return Goods",
      "subTitle": "Coming Soon",
      "icon": Icons.move_to_inbox_outlined,
      "color": const Color(0xFF1E3A8A),
      "comingSoon": true,
      "action": "coming_soon",
      "category": "more",
    },
    {
      "title": "Suppliers",
      "subTitle": "Manage suppliers",
      "icon": Icons.business_outlined,
      "color": Colors.grey,
      "comingSoon": true,
      "action": "coming_soon",
      "category": "more",
    },
  ];

  Widget syncWatcher() {
    return BlocListener<ShopFrontConnectionBloc, ShopfrontConnectionStates>(
      listenWhen: (previous, current) =>
          previous is! ConnectedToShopfront && current is ConnectedToShopfront,
      listener: (context, state) {
        if (state is ConnectedToShopfront) {
          runSequentialStockThenCustomerSync(context);
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

/// Carousel widget for Coming Soon items with pagination dots
class _ComingSoonCarousel extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final int itemsPerPage;
  final int pageCount;
  final bool isTablet;
  final AppThemeColors colors;
  final void Function(String?) onItemTap;

  const _ComingSoonCarousel({
    required this.items,
    required this.itemsPerPage,
    required this.pageCount,
    required this.isTablet,
    required this.colors,
    required this.onItemTap,
  });

  @override
  State<_ComingSoonCarousel> createState() => _ComingSoonCarouselState();
}

class _ComingSoonCarouselState extends State<_ComingSoonCarousel> {
  int _currentPage = 0;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double itemSize = widget.isTablet ? 56.0 : 50.0;
    final double carouselHeight = itemSize + 32; // icon + label

    return Column(
      children: [
        SizedBox(
          height: carouselHeight,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemCount: widget.pageCount,
            itemBuilder: (context, pageIndex) {
              final startIndex = pageIndex * widget.itemsPerPage;
              final endIndex = (startIndex + widget.itemsPerPage).clamp(
                0,
                widget.items.length,
              );
              final pageItems = widget.items.sublist(startIndex, endIndex);

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: pageItems.map((item) {
                  return Flexible(
                    child: _buildCircularIconButton(item, itemSize),
                  );
                }).toList(),
              );
            },
          ),
        ),
        if (widget.pageCount > 1) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.pageCount, (index) {
              final bool isActive = index == _currentPage;
              return GestureDetector(
                onTap: () {
                  _pageController.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: isActive ? 20 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isActive
                        ? kPrimaryColor
                        : Colors.white24,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }

  Widget _buildCircularIconButton(Map<String, dynamic> item, double size) {
    final IconData icon = item['icon'] ?? Icons.help_outline;
    final String title = item['title'] ?? '';
    final double iconSize = widget.isTablet ? 26.0 : 22.0;

    return GestureDetector(
      onTap: () => widget.onItemTap(item['action'] as String?),
      child: SizedBox(
        width: size + 12,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white12,
                  width: 1,
                ),
              ),
              child: Icon(
                icon,
                size: iconSize,
                color: Colors.white38,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: widget.isTablet ? 11 : 10,
                fontWeight: FontWeight.w400,
                color: Colors.white54,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}