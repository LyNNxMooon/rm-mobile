import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rmmobile/utils/navigation_extension.dart';
import 'package:rmmobile/utils/dependency_injection_utils.dart' as di;
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
    final bool isTablet = context.isTablet;
    final bool isPortrait = context.isPortrait;
    final colors = context.appColors;
    final media = MediaQuery.of(context);
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
            
            return Scaffold(
              extendBody: true,
              backgroundColor: kPrimaryColor,
              bottomNavigationBar: isProStyle ? _buildBottomNav(context) : null,
              body: Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(gradient: colors.heroGradient),
                child: SafeArea(
                  bottom: false,
                  top: true,
                  child: isProStyle
                      ? Stack(
                          children: [
                            Column(
                              children: [
                                if (!isTablet) const SizedBox(height: 8),
                                const AppBarSession(),
                                Expanded(child: _buildHomeBody(context)),
                              ],
                            ),
                            syncWatcher(),
                          ],
                        )
                      : Stack(
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
          },
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

  Widget _buildHomeBody(BuildContext context) {
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

    return Container(
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: colors.isDark ? colors.surface : const Color(0xFFF6F7F9),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(isTablet ? 28 : 20),
          topRight: Radius.circular(isTablet ? 28 : 20),
        ),
        boxShadow: [
          BoxShadow(
            color: colors.cardShadow,
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          bottom: 80 + MediaQuery.of(context).padding.bottom,
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
              ),
            ),
            if (isHomeTab && comingSoonItems.isNotEmpty)
              _buildComingSoonSection(context, comingSoonItems),
            if (isTablet) const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }

  Widget _buildGreetingHeader(BuildContext context) {
    final colors = context.appColors;
    final bool isTablet = context.isTablet;
    final String shopfront = (AppGlobals.instance.shopfront ?? "").trim();
    final String shopName = shopfront.isEmpty
        ? "Your shopfront"
        : shopfront.split(r'\\').last;
    final String staffName = (AppGlobals.instance.staffName ?? "").trim();
    final String staffLabel = staffName.isEmpty
        ? "Staff: Not signed in"
        : "Staff: $staffName";

    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final String logoAsset = isDark
        ? "assets/images/trademark_dark.png"
        : "assets/images/trademark.png";

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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        shopName,
                        style: getSmartTitle(
                          fontSize: isTablet ? 24 : 18,
                          color: colors.isDark
                              ? Colors.white
                              : colors.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        staffLabel,
                        style: TextStyle(
                          color: colors.isDark
                              ? Colors.white60
                              : Colors.blueGrey.shade700,
                          fontSize: isTablet ? 14 : 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Image.asset(
                  logoAsset,
                  height: isTablet ? 64 : 36,
                  fit: BoxFit.contain,
                ),
              ],
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
            final String ip = (AppGlobals.instance.currentHostIp ?? "").trim();
            final bool isOffline = ip.isEmpty;
            final bool isSyncing = _isSyncInProgress(context);
            return Wrap(
              spacing: isTablet ? 10 : 6,
              runSpacing: isTablet ? 10 : 6,
              children: [
                _buildStatusPill(
                  context,
                  label: isOffline ? "Offline" : "Server IP: $ip",
                  icon: Icons.cloud_outlined,
                  color: isOffline ? Colors.amber : kPrimaryColor,
                ),
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
                      color: kThirdColor.withOpacity(0.9),
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
    final colors = context.appColors;
    final bool isTablet = context.isTablet;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 14 : 10,
        vertical: isTablet ? 8 : 5,
      ),
      decoration: BoxDecoration(
        color: colors.isDark ? colors.surfaceAlt : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colors.isDark ? Colors.white12 : Colors.grey.shade200,
        ),
        boxShadow: [
          if (!colors.isDark)
            BoxShadow(
              color: colors.cardShadow.withOpacity(0.10),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: isTablet ? 16 : 12, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: isTablet ? 13 : 10,
              fontWeight: FontWeight.w600,
              color: colors.isDark ? Colors.white70 : Colors.blueGrey.shade700,
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
    final colors = context.appColors;
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
              color: colors.isDark ? Colors.white70 : colors.onSurface,
            ),
            const SizedBox(width: 8),
          ],
          Text(
            title,
            style: getSmartTitle(
              fontSize: isTablet ? 18 : 16,
              color: colors.isDark ? Colors.white : colors.onSurface,
            ).copyWith(height: compact ? 1.0 : null),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              height: 1.5,
              color: colors.isDark ? Colors.white30 : const Color(0xFFCECECE),
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
  }) {
    final bool isTablet = context.isTablet;
    final double width = MediaQuery.of(context).size.width;
    final bool isLargeFont = context.read<FontSizeCubit>().isLarge;
    int crossAxisCount = isTablet ? 3 : 2;
    if (width > 900) crossAxisCount = 4;
    if (width < 360) crossAxisCount = 1;

    final double spacing = isTablet ? 16 : 10;
    final double mainSpacing = compact ? 0 : (isTablet ? 12 : 8);
    final double horizontalPadding = isTablet ? 22 : 16;
    final double availableWidth =
        width - (horizontalPadding * 2) - (spacing * (crossAxisCount - 1));
    final double itemWidth = availableWidth / crossAxisCount;
    // Increase height for large font mode to prevent overflow
    final double baseHeight = isTablet ? 130 : 90;
    final double targetHeight = isLargeFont ? baseHeight * 1.15 : baseHeight;
    final double childAspectRatio = itemWidth / targetHeight;

    return Padding(
      key: key,
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: BlocBuilder<SessionCountsCubit, SessionCountsState>(
        builder: (context, sessionState) {
          //final sessionCounts = sessionState.counts;
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
              return _buildActionTile(context, item, badgeCount: 0);
            },
          );
        },
      ),
    );
  }

  Widget _buildComingSoonSection(
    BuildContext context,
    List<Map<String, dynamic>> comingSoonItems,
  ) {
    final colors = context.appColors;
    final bool isTablet = context.isTablet;
    final double screenWidth = MediaQuery.of(context).size.width;
    // Calculate items per page based on available width
    final double availableWidth = screenWidth - 44 - 32; // margins and padding
    final double itemWidth = isTablet ? 80.0 : 70.0;
    final int itemsPerPage = (availableWidth / itemWidth).floor().clamp(3, 7);
    final int pageCount = (comingSoonItems.length / itemsPerPage).ceil();

    // Simple consistent gap - same as section header top padding
    final double topMargin = isTablet ? 50 : 30;

    return Container(
      margin: EdgeInsets.fromLTRB(isTablet ? 22 : 16, topMargin, isTablet ? 22 : 16, 8),
      padding: EdgeInsets.fromLTRB(
        isTablet ? 14 : 12,
        10,
        isTablet ? 14 : 12,
        14,
      ),
      decoration: BoxDecoration(
        color: colors.isDark
            ? colors.surfaceAlt.withOpacity(0.98)
            : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: colors.isDark
              ? Colors.white10
              : Colors.grey.shade200.withOpacity(0.8),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.isDark
                ? Colors.black.withOpacity(0.06)
                : colors.cardShadow.withOpacity(0.08),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with title
          Row(
            children: [
              Icon(
                Icons.upcoming_outlined,
                size: isTablet ? 18 : 14,
                color: colors.isDark ? Colors.white54 : Colors.grey.shade600,
              ),
              const SizedBox(width: 4),
              Text(
                "More Actions",
                style: getSmartTitle(
                  fontSize: isTablet ? 14 : 12,
                  color: colors.isDark ? Colors.white70 : Colors.grey.shade700,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 6 : 4,
                  vertical: 1,
                ),
                decoration: BoxDecoration(
                  color: colors.isDark ? Colors.white10 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  "Coming Soon",
                  style: TextStyle(
                    fontSize: isTablet ? 9 : 8,
                    fontWeight: FontWeight.w600,
                    color: colors.isDark
                        ? Colors.white54
                        : Colors.grey.shade500,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                isTablet ? "Under construction" : "In dev",
                style: TextStyle(
                  fontSize: isTablet ? 11 : 10,
                  fontWeight: FontWeight.w600,
                  color: kPrimaryColor,
                ),
              ),
            ],
          ),
          SizedBox(height: isTablet ? 14 : 10),
          // Carousel of circular icon buttons
          _ComingSoonCarousel(
            items: comingSoonItems,
            itemsPerPage: itemsPerPage,
            pageCount: pageCount,
            isTablet: isTablet,
            colors: colors,
            onItemTap: _handleActionTap,
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile(
    BuildContext context,
    Map<String, dynamic> item, {
    int badgeCount = 0,
  }) {
    final colors = context.appColors;
    final bool isTablet = context.isTablet;
    final double scale = isTablet
        ? (MediaQuery.of(context).size.shortestSide / 768).clamp(0.9, 1.25)
        : 1.0;
    final double titleSize = isTablet ? (15 * scale).clamp(15.0, 19.0) : 13.0;
    final double subTitleSize = isTablet
        ? (12 * scale).clamp(12.0, 14.0)
        : 11.0;
    final double iconSize = isTablet ? 34.0 : 22.0;

    final bool isComingSoon = item['comingSoon'] ?? false;
    final Color itemColor = item['color'] ?? kPrimaryColor;
    final Color titleColor = isComingSoon
        ? Colors.grey.shade500
        : (colors.isDark ? Colors.white : colors.onSurface);
    final Color subtitleColor = isComingSoon
        ? Colors.grey.shade400
        : (colors.isDark
              ? colors.onSurfaceMuted
              : kThirdColor.withOpacity(0.78));
    final Color iconColor = isComingSoon ? Colors.grey.shade500 : itemColor;
    final Color background = isComingSoon
        ? (colors.isDark ? Colors.white10 : Colors.grey.shade100)
        : (colors.isDark ? colors.surfaceAlt.withOpacity(0.98) : Colors.white);

    return InkWell(
      onTap: () => _handleActionTap(item['action'] as String?),
      borderRadius: BorderRadius.circular(10),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isComingSoon
                    ? Colors.transparent
                    : (colors.isDark
                          ? Colors.white10
                          : Colors.grey.shade200.withOpacity(0.8)),
                width: 1,
              ),
              boxShadow: isComingSoon
                  ? []
                  : [
                      BoxShadow(
                        color: colors.isDark
                            ? Colors.black.withOpacity(0.02)
                            : colors.cardShadow.withOpacity(0.04),
                        blurRadius: 1,
                        offset: const Offset(0, 1),
                      ),
                    ],
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                isTablet ? 12 : 10,
                isTablet ? 16 : 10,
                isTablet ? 10 : 8,
                isTablet ? 16 : 10,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isTablet ? 8 : 6,
                        vertical: isTablet ? 0 : 0,
                      ),
                      decoration: BoxDecoration(
                        color: colors.isDark
                            ? Colors.white10
                            : Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(isTablet ? 8 : 6),
                        border: Border.all(
                          color: colors.isDark
                              ? Colors.white10
                              : Colors.grey.shade200,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: colors.isDark
                                ? Colors.black.withOpacity(0.04)
                                : colors.cardShadow.withOpacity(0.06),
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              item['title'],
                              style: getSmartTitle(
                                fontSize: titleSize,
                                color: titleColor,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(height: isTablet ? 4 : 2),
                          Text(
                            item['subTitle'],
                            style: TextStyle(
                              fontSize: subTitleSize,
                              fontWeight: FontWeight.w600,
                              color: subtitleColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: isTablet ? 10 : 6),
                  Container(
                    padding: EdgeInsets.all(isTablet ? 6 : 4),
                    decoration: BoxDecoration(
                      color: colors.isDark
                          ? Colors.black.withOpacity(0.18)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      item['icon'],
                      size: iconSize,
                      color: iconColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 0,
            bottom: 0,
            left: 0,
            child: Container(
              width: 8,
              decoration: BoxDecoration(
                color: itemColor.withOpacity(isComingSoon ? 0.25 : 1.0),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                ),
              ),
            ),
          ),
          if (badgeCount > 0)
            Positioned(
              left: 12,
              top: 10,
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
                      color: Colors.red.withOpacity(0.25),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
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
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    final colors = context.appColors;
    return BottomNavigationBar(
      currentIndex: _selectedTabIndex,
      type: BottomNavigationBarType.fixed,
      backgroundColor: colors.isDark ? colors.surface : Colors.white,
      selectedItemColor: kPrimaryColor,
      unselectedItemColor: colors.onSurfaceMuted,
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
        return "Actions";
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
      context
          .navigateToNext(
            BlocProvider(
              create: (_) => di.sl<SalesBloc>(),
              child: const SalesScreen(
                title: "Sales",
                themeColor: Colors.green,
                icon: Icons.point_of_sale_outlined,
              ),
            ),
          )
          .then((_) => _sessionCountsCubit.loadSessionCounts());
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
      context
          .navigateToNext(
            BlocProvider(
              create: (_) => di.sl<SalesBloc>(),
              child: const SalesScreen(
                title: "Account Sales",
                themeColor: Color.fromARGB(255, 238, 130, 166),
                icon: Icons.receipt_long_outlined,
              ),
            ),
          )
          .then((_) => _sessionCountsCubit.loadSessionCounts());
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
      context
          .navigateToNext(
            BlocProvider(
              create: (_) => di.sl<SalesBloc>(),
              child: const SalesScreen(
                title: "Sales Order",
                themeColor: Color.fromARGB(255, 44, 133, 211),
                icon: Icons.shopping_cart_outlined,
              ),
            ),
          )
          .then((_) => _sessionCountsCubit.loadSessionCounts());
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
      context
          .navigateToNext(
            BlocProvider(
              create: (_) => di.sl<SalesBloc>(),
              child: const SalesScreen(
                title: "Quotes",
                themeColor: Colors.orange,
                icon: Icons.request_quote_outlined,
              ),
            ),
          )
          .then((_) => _sessionCountsCubit.loadSessionCounts());
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
      context
          .navigateToNext(
            BlocProvider(
              create: (_) => di.sl<SalesBloc>(),
              child: const SalesScreen(
                title: "Lay-bys",
                themeColor: Color.fromARGB(255, 152, 86, 165),
                icon: Icons.inventory_2_outlined,
              ),
            ),
          )
          .then((_) => _sessionCountsCubit.loadSessionCounts());
      return;
    }

    context.navigateToNext(const ComingSoonScreen());
  }

  final List<Map<String, dynamic>> _actionItems = [
    {
      "title": "Account Sales",
      "subTitle": "Create account sale",
      "icon": Icons.receipt_long_outlined,
      "color": const Color.fromARGB(255, 238, 130, 166),
      "comingSoon": false,
      "action": "account_sales",
      "category": "sales",
    },
    {
      "title": "Sales Order",
      "subTitle": "Create sales order",
      "icon": Icons.shopping_cart_outlined,
      "color": const Color.fromARGB(255, 44, 133, 211),
      "comingSoon": false,
      "action": "sales_order",
      "category": "sales",
    },
    {
      "title": "Quotes",
      "subTitle": "Create quotation",
      "icon": Icons.request_quote_outlined,
      "color": Colors.orange.shade500,
      "comingSoon": false,
      "action": "quotes",
      "category": "sales",
    },
    {
      "title": "Lay-bys",
      "subTitle": "Create lay-by",
      "icon": Icons.inventory_2_outlined,
      "color": const Color.fromARGB(255, 152, 86, 165),
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
      "subTitle": "POS transactions",
      "icon": Icons.point_of_sale_outlined,
      "color": Colors.grey,
      "comingSoon": true,
      "action": "sales",
      "category": "more",
    },
    {
      "title": "Goods Received",
      "subTitle": "Receive stock",
      "icon": Icons.local_shipping_outlined,
      "color": Colors.grey,
      "comingSoon": true,
      "action": "coming_soon",
      "category": "more",
    },
    {
      "title": "Purchase Orders",
      "subTitle": "Order stock",
      "icon": Icons.shopping_bag_outlined,
      "color": Colors.grey,
      "comingSoon": true,
      "action": "coming_soon",
      "category": "more",
    },
    {
      "title": "Return Goods",
      "subTitle": "Return stock",
      "icon": Icons.assignment_return_outlined,
      "color": Colors.grey,
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
                        : (widget.colors.isDark
                              ? Colors.white24
                              : Colors.grey.shade300),
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
                color: widget.colors.isDark
                    ? Colors.white.withOpacity(0.08)
                    : Colors.grey.shade100,
                shape: BoxShape.circle,
                border: Border.all(
                  color: widget.colors.isDark
                      ? Colors.white12
                      : Colors.grey.shade200,
                  width: 1,
                ),
              ),
              child: Icon(
                icon,
                size: iconSize,
                color: widget.colors.isDark
                    ? Colors.white38
                    : Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: widget.isTablet ? 11 : 10,
                fontWeight: FontWeight.w500,
                color: widget.colors.isDark
                    ? Colors.white54
                    : Colors.grey.shade500,
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
