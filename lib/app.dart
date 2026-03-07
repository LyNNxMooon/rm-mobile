import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rmstock_scanner/features/home_page/presentation/BLoC/home_screen_bloc.dart';
import 'package:rmstock_scanner/features/onboarding/presentation/screens/onboarding_gate_screen.dart';
//import 'package:rmstock_scanner/features/home_page/presentation/BLoC/home_screen_events.dart';
import 'package:rmstock_scanner/features/stock_lookup/presentation/BLoC/stock_lookup_bloc.dart';
import 'package:rmstock_scanner/features/customer_lookup/presentation/BLoC/customer_lookup_bloc.dart';
import 'package:rmstock_scanner/features/stocktake/presentation/BLoC/stocktake_bloc.dart';
//import 'package:rmstock_scanner/features/stocktake/presentation/screens/scanner_screen.dart';
import 'package:rmstock_scanner/utils/dependency_injection_utils.dart';
import 'package:rmstock_scanner/utils/log_utils.dart';

import 'features/loading_splash/presentation/BLoC/loading_splash_bloc.dart';
import 'features/loading_splash/presentation/BLoC/loading_splash_events.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  double _tabletTextScaleFor(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final double shortestSide = size.shortestSide;
    final double longestSide = size.longestSide;

    // Keep mobile unchanged.
    if (shortestSide < 600) return 1.0;

    // Tablet/iPad adaptive scale for portrait + landscape.
    // Use stronger scaling for large tablets/iPads.
    if (shortestSide >= 900 || longestSide >= 1366) {
      return 1.60;
    }
    if (shortestSide >= 820 || longestSide >= 1200) {
      return 1.50;
    }
    if (shortestSide >= 720 || longestSide >= 1100) {
      return 1.42;
    }
    return 1.34;
  }

  double _tabletUiScaleFor(double textScale) {
    if (textScale <= 1.0) return 1.0;
    final double scaled = 1.0 + ((textScale - 1.0) * 0.65);
    return scaled.clamp(1.0, 1.42);
  }

  @override
  initState() {
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
        BlocProvider<GettingDirectoryBloc>(
          create: (_) => sl<GettingDirectoryBloc>(),
        ),
        BlocProvider<ConnectingFolderBloc>(
          create: (_) => sl<ConnectingFolderBloc>(),
        ),
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
        BlocProvider<StocktakeLimitBloc>(
          create: (_) => sl<StocktakeLimitBloc>(),
        ),
        BlocProvider<AutoConnectionBloc>(
          create: (_) => sl<AutoConnectionBloc>(),
        ),
        BlocProvider<FetchStockBloc>(create: (_) => sl<FetchStockBloc>()),
        BlocProvider<StockListBloc>(create: (_) => sl<StockListBloc>()),
        BlocProvider<FilterOptionsBloc>(create: (_) => sl<FilterOptionsBloc>()),
        BlocProvider<FetchCustomerBloc>(create: (_) => sl<FetchCustomerBloc>()),
        BlocProvider<CustomerListBloc>(create: (_) => sl<CustomerListBloc>()),
        BlocProvider<CustomerFilterOptionsBloc>(create: (_) => sl<CustomerFilterOptionsBloc>()),
        BlocProvider<StaffDetailBloc>(create: (_) => sl<StaffDetailBloc>()),
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

        //Local web server changes
        BlocProvider<DiscoverHostBloc>(create: (_) => sl<DiscoverHostBloc>()),
        BlocProvider<PairCodeBloc>(create: (_) => sl<PairCodeBloc>()),
        BlocProvider<PairDeviceBloc>(create: (_) => sl<PairDeviceBloc>()),
        BlocProvider<StaffAuthBloc>(create: (_) => sl<StaffAuthBloc>()),
      ],
      child: MaterialApp(
        title: 'RM-Mobile',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(fontFamily: "Inter"),
        builder: (context, child) {
          final media = MediaQuery.of(context);
          final double textScale = _tabletTextScaleFor(context);
          final double uiScale = _tabletUiScaleFor(textScale);
          final ThemeData baseTheme = Theme.of(context);
          final double densityAdjust = ((uiScale - 1.0) * 3.2).clamp(0.0, 1.35);
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
      ),
    );
  }
}
