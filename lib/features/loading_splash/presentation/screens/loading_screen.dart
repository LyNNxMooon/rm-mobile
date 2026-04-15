import 'dart:ui'; // Required for ImageFilter (Blur)
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rmmobile/features/customer_lookup/presentation/BLoC/customer_lookup_bloc.dart';
import 'package:rmmobile/features/customer_lookup/presentation/BLoC/customer_lookup_events.dart';
import 'package:rmmobile/features/home_page/presentation/BLoC/home_screen_bloc.dart';
import 'package:rmmobile/features/home_page/presentation/BLoC/home_screen_events.dart';
import 'package:rmmobile/features/home_page/presentation/BLoC/home_screen_states.dart';
import 'package:rmmobile/features/home_page/presentation/screens/staff_login_screen.dart';
import 'package:rmmobile/features/loading_splash/presentation/BLoC/loading_splash_bloc.dart';
import 'package:rmmobile/utils/global_var_utils.dart';
import 'package:rmmobile/utils/log_utils.dart';
import 'package:rmmobile/utils/navigation_extension.dart';
import 'package:rmmobile/utils/responsive_utils.dart';

//import '../../../../constants/theme_colors.dart';
//import '../../../../constants/global_widgets.dart';
import '../../../../constants/images.dart';
//import '../../../../constants/txt_styles.dart';
import '../BLoC/loading_splash_events.dart';
import '../BLoC/loading_splash_states.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with SingleTickerProviderStateMixin {
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
  bool _assetsPrecached = false;
  bool _uiReady = false;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    // Slightly slower pulse for a more premium feel
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500), 
    )..repeat(reverse: true);
    
    // Subtle scaling for the logo
    _pulseAnimation = Tween<double>(begin: 0.98, end: 1.02).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_assetsPrecached) return;
    _assetsPrecached = true;
    
    // Precache both the logo and the background images for smooth rendering
    Future.wait([
      precacheImage(const AssetImage(appLogoSquare), context), // Ensure this maps to your new blue square logo in images.dart
      precacheImage(const AssetImage(bgPortrait), context),    // Ensure this maps to portrait.jpg
      precacheImage(const AssetImage(bgLandscape), context),   // Ensure this maps to landscape.jpg
    ]).then((_) {
      if (!mounted) return;
      setState(() {
        _uiReady = true;
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
    final isTablet = context.isTablet;
    // Determine orientation to pick the right background image
    final isLandscape = MediaQuery.orientationOf(context) == Orientation.landscape;
    
    // Responsive sizing - made larger for better visual impact
    final double logoSize = isTablet ? 180 : 130;
    final String bgImage = isLandscape ? bgLandscape : bgPortrait;

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
        backgroundColor: Colors.black, // Fallback color
        body: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Contextual Background Image
            AnimatedOpacity(
              opacity: _uiReady ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 800),
              child: Image.asset(
                bgImage,
                fit: BoxFit.cover,
              ),
            ),

            // 2. Dark Gradient & Blur Overlay
            // This ensures text is ALWAYS readable regardless of the photo beneath
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.5),
                      Colors.black.withOpacity(0.7), // Darker at bottom for footer
                    ],
                  ),
                ),
              ),
            ),

            // 3. Main Foreground Content
            SafeArea(
              child: AnimatedOpacity(
                opacity: _uiReady ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 1000),
                child: Column(
                  children: [
                    const Spacer(flex: 3), // Pushes content slightly above center

                    // --- HERO LOGO ---
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _pulseAnimation.value,
                          child: child,
                        );
                      },
                      child: Container(
                        width: logoSize,
                        height: logoSize,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(logoSize * 0.22),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.5),
                              blurRadius: 40,
                              offset: const Offset(0, 20),
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(logoSize * 0.22),
                          child: Image.asset(appLogoSquare, fit: BoxFit.cover),
                        ),
                      ),
                    ),
                    SizedBox(height: isTablet ? 36 : 28),

                    // --- APP TITLE ---
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: "RetailManager ",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isTablet ? 38 : 30,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.5,
                            ),
                          ),
                          TextSpan(
                            text: "Mobile",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: isTablet ? 38 : 30,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: isTablet ? 12 : 8),
                    
                    // --- TAGLINE ---
                    Text(
                      "Point of Sale, Simplified",
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: isTablet ? 16 : 14,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.8,
                      ),
                    ),

                    const Spacer(flex: 2),

                    // --- MODERN LOADING PILL ---
                    ClipRRect(
                      borderRadius: BorderRadius.circular(35),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isTablet ? 28 : 24,
                            vertical: isTablet ? 14 : 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(35),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.25),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: isTablet ? 20 : 16,
                                height: isTablet ? 20 : 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: isTablet ? 2.5 : 2,
                                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              ),
                              SizedBox(width: isTablet ? 16 : 14),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                child: Text(
                                  _loadingMessage,
                                  key: ValueKey(_loadingMessage),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: isTablet ? 15 : 14,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const Spacer(flex: 2),

                    // --- FOOTER (Powered By) ---
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "POWERED BY",
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: isTablet ? 12 : 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 2.0,
                          ),
                        ),
                        SizedBox(height: isTablet ? 12 : 10),
                        // Wrap AAAPOS in a white pill because the logo text is dark
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Image.asset(
                            aaaposLogo,
                            height: isTablet ? 32 : 22,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: isTablet ? 40 : 32), // Bottom padding
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}