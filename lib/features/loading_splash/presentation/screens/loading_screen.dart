import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rmstock_scanner/features/customer_lookup/presentation/BLoC/customer_lookup_bloc.dart';
import 'package:rmstock_scanner/features/customer_lookup/presentation/BLoC/customer_lookup_events.dart';
import 'package:rmstock_scanner/features/home_page/presentation/BLoC/home_screen_bloc.dart';
import 'package:rmstock_scanner/features/home_page/presentation/BLoC/home_screen_events.dart';
import 'package:rmstock_scanner/features/home_page/presentation/BLoC/home_screen_states.dart';
import 'package:rmstock_scanner/features/home_page/presentation/screens/staff_login_screen.dart';
import 'package:rmstock_scanner/features/loading_splash/presentation/BLoC/loading_splash_bloc.dart';
import 'package:rmstock_scanner/utils/global_var_utils.dart';
import 'package:rmstock_scanner/utils/log_utils.dart';
import 'package:rmstock_scanner/utils/navigation_extension.dart';
import 'package:rmstock_scanner/utils/responsive_utils.dart';

import '../../../../constants/theme_colors.dart';
import '../../../../constants/global_widgets.dart';
import '../../../../constants/images.dart';
import '../../../../constants/txt_styles.dart';
import '../BLoC/loading_splash_events.dart';
import '../BLoC/loading_splash_states.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  String _loadingMessage = "Checking Connection...";
  String? _savedStaffNo;
  String? _savedPassword;
  int? _port;
  String _apiKey = "";
  String _shopfrontId = "";
  String _shopfrontName = "";
  bool _authAttempted = false;
  bool _autoConnectAttempted = false;
  bool _loginPrompted = false;
  bool _logoPrecached = false;
  bool _logoReady = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_logoPrecached) return;
    _logoPrecached = true;
    precacheImage(AssetImage(appLogo), context).then((_) {
      if (!mounted) return;
      setState(() {
        _logoReady = true;
      });
    });
  }

  void _requestSavedInfo() {
    context.read<StaffAuthBloc>().add(LoadConnectionInfoEvent());
    context.read<StaffAuthBloc>().add(LoadSavedStaffCredentialsEvent());
  }

  void _attemptAutoAuth() {
    if (_authAttempted || !mounted) return;
    if (context.read<ShopFrontConnectionBloc>().state
        is! ConnectedToShopfront) {
      logger.d("Splash auto-auth skipped: shopfront not connected yet.");
      return;
    }
    _authAttempted = true;

    final ip = (AppGlobals.instance.currentHostIp ?? "").trim();
    if (_savedStaffNo == null || _savedStaffNo!.isEmpty) {
      logger.d("Splash auto-auth skipped: missing saved staff number.");
      _navigateToStaffLogin();
      return;
    }

    if (ip.isEmpty ||
        _port == null ||
        _apiKey.isEmpty ||
        _shopfrontId.isEmpty ||
        _shopfrontName.isEmpty) {
      logger.d("Splash auto-auth skipped: missing connection/shopfront info.");
      _navigateToStaffLogin();
      return;
    }

    logger.d("Splash auto-auth dispatching AuthenticateStaffEvent.");
    context.read<StaffAuthBloc>().add(
      AuthenticateStaffEvent(
        ip: ip,
        port: _port!,
        apiKey: _apiKey,
        shopfrontId: _shopfrontId,
        shopfrontName: _shopfrontName,
        staffNo: _savedStaffNo!,
        password: _savedPassword!,
      ),
    );
  }

  Future<void> _attemptAutoShopfrontConnect() async {
    if (_autoConnectAttempted || !mounted) return;
    if (context.read<ShopFrontConnectionBloc>().state is ConnectedToShopfront) {
      return;
    }

    final ip = (AppGlobals.instance.currentHostIp ?? "").trim();
    if (ip.isEmpty ||
        _port == null ||
        _apiKey.isEmpty ||
        _shopfrontId.isEmpty ||
        _shopfrontName.isEmpty) {
      logger.d(
        "Splash auto-connect skipped: missing connection/shopfront info.",
      );
      return;
    }

    _autoConnectAttempted = true;
    logger.d("Splash auto-connecting shopfront via API.");
    context.read<ShopFrontConnectionBloc>().add(
      ConnectToShopfrontApiEvent(
        ip: ip,
        port: _port!,
        apiKey: _apiKey,
        shopfrontId: _shopfrontId,
        shopfrontName: _shopfrontName,
      ),
    );
  }

  void _navigateToStaffLogin() {
    if (_loginPrompted || !mounted) return;
    _loginPrompted = true;
    context.navigateToNext(const StaffLoginScreen());
  }

  void _startDataSync(BuildContext context) {
    // Start syncs in background - don't wait for them
    context.read<FetchStockBloc>().add(StartSyncEvent(ipAddress: ""));
    context.read<FetchCustomerBloc>().add(
      StartCustomerSyncEvent(ipAddress: ""),
    );
    // Navigation will happen automatically via IndexScreen state change
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final bool isDark = colors.isDark;
    final bool isTablet = context.isTablet;
    final double logoWidth = isTablet ? 260 : 160;
    final double logoHeight = isTablet ? 188 : 120;
    //final double loadingWidth = isTablet ? 280 : 220;

    return MultiBlocListener(
      listeners: [
        BlocListener<NetworkSavedPathValidationBloc, LoadingSplashStates>(
          listener: (context, state) {
            if (state is SavedPathFetchingCompleted) {
              context.read<NetworkSavedPathValidationBloc>().add(
                ConnectionCheckingEvent(
                  state.paths.first['path']?.toString() ?? "",
                ),
              );
            }

            if (state is ConnectionValid) {
              // After connection is valid, load connection info and prompt for authentication
              if (mounted) {
                setState(() {
                  _loadingMessage = "Loading...";
                });
              }
              _requestSavedInfo();
            }

            if (state is ErrorCheckingConnection ||
                state is ErrorFetchingSavedPaths) {
              // Connection errors - allow HomeScreen to prompt for network setup
              if (mounted) {
                setState(() {
                  _loadingMessage = "Waiting for setup...";
                });
              }
            }
          },
        ),
        BlocListener<ShopFrontConnectionBloc, ShopfrontConnectionStates>(
          listener: (context, state) {
            if (state is ConnectedToShopfront && !_authAttempted) {
              if (mounted) {
                setState(() {
                  _loadingMessage = "Authenticating...";
                });
              }
              _requestSavedInfo();
            }
          },
        ),
        BlocListener<StaffAuthBloc, StaffAuthStates>(
          listener: (context, state) {
            if (state is StaffConnectionInfoLoaded) {
              setState(() {
                _port = state.port;
                _apiKey = state.apiKey;
                _shopfrontId = state.shopfrontId;
                _shopfrontName = state.shopfrontName;
              });
              _attemptAutoShopfrontConnect();
            }
            if (state is StaffCredentialsLoaded) {
              setState(() {
                _savedStaffNo = state.staffNo.trim();
                _savedPassword = state.password.trim();
              });
              _attemptAutoAuth();
            }
            if (state is StaffAuthenticated) {
              setState(() {
                _loadingMessage = "Syncing Data...";
              });
              _startDataSync(context);
            }

            if (state is StaffUnauthenticated || state is StaffAuthError) {
              _navigateToStaffLogin();
            }
          },
        ),
      ],
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(gradient: colors.heroGradient),
          child: SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: logoWidth,
                    height: logoHeight,
                    child: Image.asset(
                      appLogo,
                      fit: BoxFit.fill,
                      //gaplessPlayback: true,
                    ),
                  ),
                  const SizedBox(height: 20),
                  AnimatedOpacity(
                    opacity: _logoReady ? 1 : 0,
                    duration: const Duration(milliseconds: 150),
                    child: Column(
                      children: [
                        Text(
                          "RetailManager Mobile",
                          style: getSmartTitle(
                            color: isDark ? Colors.white : colors.onHero,
                            fontSize: 24,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          "AAAPOS Pty Ltd",
                          style: TextStyle(
                            color: isDark
                                ? Colors.white70
                                : colors.onHero.withOpacity(0.8),
                            fontWeight: FontWeight.w400,
                            fontSize: 16,
                          ),
                        ),

                   
                        LottieLoadingBar(),
                       
                        Text(
                          _loadingMessage,
                          style: TextStyle(
                            color: isDark
                                ? Colors.white70
                                : colors.onHero.withOpacity(0.8),
                            fontWeight: FontWeight.w400,
                            fontSize: 12,
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
}
