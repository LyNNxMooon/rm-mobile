import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rmmobile/features/home_page/presentation/BLoC/home_screen_bloc.dart';
import 'package:rmmobile/features/theme/presentation/bloc/theme_cubit.dart';
import 'package:rmmobile/features/home_page/presentation/BLoC/dashboard_style_cubit.dart';
import 'package:rmmobile/features/home_page/presentation/BLoC/font_size_cubit.dart';
//import 'package:rmmobile/features/loading_splash/presentation/screens/loading_screen.dart';
import 'package:rmmobile/features/onboarding/presentation/screens/onboarding_gate_screen.dart';
import 'package:rmmobile/features/onboarding/presentation/BLoC/onboarding_bloc.dart';
//import 'package:rmmobile/features/home_page/presentation/BLoC/home_screen_events.dart';
import 'package:rmmobile/features/stock_lookup/presentation/BLoC/stock_lookup_bloc.dart';
import 'package:rmmobile/features/stock_lookup/presentation/BLoC/package_component_bloc.dart';
import 'package:rmmobile/features/customer_lookup/presentation/BLoC/customer_lookup_bloc.dart';
import 'package:rmmobile/features/customer_lookup/presentation/BLoC/customer_create_bloc.dart';
import 'package:rmmobile/features/customer_lookup/presentation/BLoC/customer_transactions_bloc.dart';
import 'package:rmmobile/features/customer_lookup/presentation/BLoC/staff_barcode_lookup_bloc.dart';
import 'package:rmmobile/features/stocktake/presentation/BLoC/stocktake_bloc.dart';
import 'package:rmmobile/features/stocktake/presentation/BLoC/batch_commit_bloc.dart';
//import 'package:rmmobile/features/stocktake/presentation/screens/scanner_screen.dart';
import 'package:rmmobile/utils/dependency_injection_utils.dart';
import 'package:rmmobile/utils/log_utils.dart';
import 'package:rmmobile/utils/responsive_utils.dart';
import 'package:rmmobile/utils/route_observer.dart';

import 'features/loading_splash/presentation/BLoC/loading_splash_bloc.dart';
import 'features/loading_splash/presentation/BLoC/loading_splash_events.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  /// Calculate text scale using centralized responsive utilities.
  double _tabletTextScaleFor(BuildContext context) {
    return context.responsive.textScale;
  }

  /// Calculate UI scale from text scale using centralized responsive utilities.
  double _tabletUiScaleFor(BuildContext context) {
    return context.responsive.uiScale;
  }

  @override
  initState() {
    if (!sl.isRegistered<OnboardingBloc>()) {
      init();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndRequestPermission();
    });
    super.initState();
  }

  Future<void> _checkAndRequestPermission() async {
    var status = await Permission.locationWhenInUse.status;

    if (!status.isGranted) {
      status = await Permission.locationWhenInUse.request();
    }

    logger.d("Location Status: $status");

    if (status.isPermanentlyDenied) {
      _showSettingsDialog();
      return;
    }
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Location Access Required"),
        content: Text(
          "To scan your local network, please enable 'While Using the App' and 'Precise Location' in Settings.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: Text("Open Settings"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<StocktakeBloc>(create: (_) => sl<StocktakeBloc>()),
        BlocProvider<FetchingNetworkServerBloc>(
          create: (_) => sl<FetchingNetworkServerBloc>(),
        ),
        // SMB LEGACY - Commented out
        // BlocProvider<GettingDirectoryBloc>(
        //   create: (_) => sl<GettingDirectoryBloc>(),
        // ),
        // BlocProvider<ConnectingFolderBloc>(
        //   create: (_) => sl<ConnectingFolderBloc>(),
        // ),
        BlocProvider<ShopfrontBloc>(create: (_) => sl<ShopfrontBloc>()),
        BlocProvider<ShopFrontConnectionBloc>(
          create: (_) => sl<ShopFrontConnectionBloc>(),
        ),
        BlocProvider<NetworkSavedPathValidationBloc>(
          create: (_) =>
              sl<NetworkSavedPathValidationBloc>()..add(FetchSavedPathsEvent()),
        ),
        BlocProvider<FetchingStocktakeListBloc>(
          create: (_) => sl<FetchingStocktakeListBloc>(),
        ),
        BlocProvider<CommittingStocktakeBloc>(
          create: (_) => sl<CommittingStocktakeBloc>(),
        ),
        BlocProvider<BatchCommitBloc>(
          create: (_) => sl<BatchCommitBloc>(),
        ),
        BlocProvider<StocktakeDeleteBloc>(
          create: (_) => sl<StocktakeDeleteBloc>(),
        ),
        BlocProvider<StocktakeLimitBloc>(
          create: (_) => sl<StocktakeLimitBloc>(),
        ),
        // SMB LEGACY - Commented out
        // BlocProvider<AutoConnectionBloc>(
        //   create: (_) => sl<AutoConnectionBloc>(),
        // ),
        BlocProvider<FetchStockBloc>(create: (_) => sl<FetchStockBloc>()),
        BlocProvider<StockListBloc>(create: (_) => sl<StockListBloc>()),
        BlocProvider<PackageComponentBloc>(
          create: (_) => sl<PackageComponentBloc>(),
        ),
        BlocProvider<FilterOptionsBloc>(create: (_) => sl<FilterOptionsBloc>()),
        BlocProvider<FetchCustomerBloc>(create: (_) => sl<FetchCustomerBloc>()),
        BlocProvider<CustomerListBloc>(create: (_) => sl<CustomerListBloc>()),
        BlocProvider<CustomerFilterOptionsBloc>(create: (_) => sl<CustomerFilterOptionsBloc>()),
        BlocProvider<StaffDetailBloc>(create: (_) => sl<StaffDetailBloc>()),
        BlocProvider<CustomerUpdateBloc>(create: (_) => sl<CustomerUpdateBloc>()),
        BlocProvider<CustomerTransactionsBloc>(
          create: (_) => sl<CustomerTransactionsBloc>(),
        ),
        BlocProvider<CustomerCreateBloc>(create: (_) => sl<CustomerCreateBloc>()),
        BlocProvider<StaffBarcodeLookupBloc>(
          create: (_) => sl<StaffBarcodeLookupBloc>(),
        ),
        BlocProvider<ScannerBloc>(create: (_) => sl<ScannerBloc>()),
        BlocProvider<StocktakeValidationBloc>(
          create: (_) => sl<StocktakeValidationBloc>(),
        ),
        BlocProvider<SendingFinalStocktakeBloc>(
          create: (_) => sl<SendingFinalStocktakeBloc>(),
        ),
        BlocProvider<ThumbnailBloc>(create: (_) => sl<ThumbnailBloc>()),
        BlocProvider<FullImageBloc>(create: (_) => sl<FullImageBloc>()),
        BlocProvider<StocktakeHistoryBloc>(
          create: (_) => sl<StocktakeHistoryBloc>(),
        ),
        BlocProvider<SettingsBloc>(create: (_) => sl<SettingsBloc>()),
        BlocProvider<StockDetailsBloc>(create: (_) => sl<StockDetailsBloc>()),
        BlocProvider<StockCountUpdateBloc>(
          create: (_) => sl<StockCountUpdateBloc>(),
        ),
        BlocProvider<StockImageUploadBloc>(
          create: (_) => sl<StockImageUploadBloc>(),
        ),
        BlocProvider<BackupStocktakeBloc>(
          create: (_) => sl<BackupStocktakeBloc>(),
        ),
        BlocProvider<BackupRestoreBloc>(create: (_) => sl<BackupRestoreBloc>()),
        BlocProvider<StockUpdateBloc>(create: (_) => sl<StockUpdateBloc>()),
        BlocProvider<PendingStockUpdatesBloc>(
          create: (_) => sl<PendingStockUpdatesBloc>(),
        ),
        BlocProvider<PendingCustomerUpdatesBloc>(
          create: (_) => sl<PendingCustomerUpdatesBloc>(),
        ),
        BlocProvider<ThemeCubit>(create: (_) => sl<ThemeCubit>()),
        BlocProvider<DashboardStyleCubit>(create: (_) => sl<DashboardStyleCubit>()),
        BlocProvider<FontSizeCubit>(create: (_) => sl<FontSizeCubit>()),

        //Local web server changes
        BlocProvider<DiscoverHostBloc>(create: (_) => sl<DiscoverHostBloc>()),
        BlocProvider<PairCodeBloc>(create: (_) => sl<PairCodeBloc>()),
        BlocProvider<PairDeviceBloc>(create: (_) => sl<PairDeviceBloc>()),
        BlocProvider<StaffAuthBloc>(create: (_) => sl<StaffAuthBloc>()),
        BlocProvider<OnboardingBloc>(create: (_) => sl<OnboardingBloc>()),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          return BlocBuilder<FontSizeCubit, String>(
            builder: (context, fontSizeSetting) {
              // Calculate font size multiplier: default = 1.0, large = 1.2
              final double fontSizeMultiplier = fontSizeSetting == "large" ? 1.2 : 1.0;
              
              return MaterialApp(
                title: 'RM-Mobile',
                debugShowCheckedModeBanner: false,
                themeMode: themeMode,
                theme: _buildTheme(Brightness.light),
                darkTheme: _buildTheme(Brightness.dark),
                navigatorObservers: [routeObserver],
                builder: (context, child) {
                  final media = MediaQuery.of(context);
                  // Apply both tablet scale and font size setting
                  final double baseTextScale = _tabletTextScaleFor(context);
                  final double textScale = (baseTextScale * fontSizeMultiplier).clamp(1.0, 1.5);
                  final double uiScale = _tabletUiScaleFor(context);
                  final ThemeData baseTheme = Theme.of(context);
              final double densityAdjust =
                  ((uiScale - 1.0) * 3.2).clamp(0.0, 1.35);
              final ThemeData scaledTheme = baseTheme.copyWith(
                visualDensity: VisualDensity(
                  horizontal: densityAdjust,
                  vertical: densityAdjust,
                ),
                listTileTheme: baseTheme.listTileTheme.copyWith(
                  minVerticalPadding: (4 * uiScale).clamp(4.0, 10.0),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: (16 * uiScale).clamp(16.0, 26.0),
                    vertical: (2 * uiScale).clamp(2.0, 8.0),
                  ),
                ),
                inputDecorationTheme: baseTheme.inputDecorationTheme.copyWith(
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: (14 * uiScale).clamp(14.0, 22.0),
                    vertical: (13 * uiScale).clamp(13.0, 20.0),
                  ),
                ),
                elevatedButtonTheme: ElevatedButtonThemeData(
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      horizontal: (18 * uiScale).clamp(18.0, 30.0),
                      vertical: (12 * uiScale).clamp(12.0, 20.0),
                    ),
                    minimumSize: Size(
                      (84 * uiScale).clamp(84.0, 130.0),
                      (42 * uiScale).clamp(42.0, 60.0),
                    ),
                  ),
                ),
                outlinedButtonTheme: OutlinedButtonThemeData(
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      horizontal: (18 * uiScale).clamp(18.0, 30.0),
                      vertical: (12 * uiScale).clamp(12.0, 20.0),
                    ),
                    minimumSize: Size(
                      (84 * uiScale).clamp(84.0, 130.0),
                      (42 * uiScale).clamp(42.0, 60.0),
                    ),
                  ),
                ),
                textButtonTheme: TextButtonThemeData(
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      horizontal: (16 * uiScale).clamp(16.0, 28.0),
                      vertical: (10 * uiScale).clamp(10.0, 18.0),
                    ),
                    minimumSize: Size(
                      (74 * uiScale).clamp(74.0, 120.0),
                      (38 * uiScale).clamp(38.0, 56.0),
                    ),
                  ),
                ),
              );

              return MediaQuery(
                data: media.copyWith(textScaler: TextScaler.linear(textScale)),
                child: Theme(
                  data: scaledTheme,
                  child: child ?? const SizedBox.shrink(),
                ),
              );
            },
            home: const OnboardingGateScreen(),
            //home: const LoadingScreen(),
          );
            },
          );
        },
      ),
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    final bool isDark = brightness == Brightness.dark;
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF0F8ABE),
      brightness: brightness,
    );

    return ThemeData(
      brightness: brightness,
      fontFamily: "Inter",
      colorScheme: scheme,
      scaffoldBackgroundColor:
          isDark ? const Color(0xFF0E1116) : const Color(0xFFF6F7F8),
      appBarTheme: AppBarTheme(
        backgroundColor:
            isDark ? const Color(0xFF0E1116) : const Color(0xFFF6F7F8),
        foregroundColor: scheme.onBackground,
        elevation: 0,
      ),
      dialogBackgroundColor:
          isDark ? const Color(0xFF151B22) : Colors.white,
      dividerColor: isDark ? const Color(0xFF222A33) : const Color(0xFFE1E5EA),
    );
  }
}
