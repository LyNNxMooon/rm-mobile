import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rmstock_scanner/features/home_page/presentation/BLoC/home_screen_bloc.dart';
//import 'package:rmstock_scanner/features/home_page/presentation/BLoC/home_screen_events.dart';
import 'package:rmstock_scanner/features/stock_lookup/presentation/BLoC/stock_lookup_bloc.dart';
import 'package:rmstock_scanner/features/stocktake/presentation/BLoC/stocktake_bloc.dart';
import 'package:rmstock_scanner/utils/dependency_injection_utils.dart';
import 'package:rmstock_scanner/utils/log_utils.dart';

import 'features/loading_splash/presentation/BLoC/loading_splash_bloc.dart';
import 'features/loading_splash/presentation/BLoC/loading_splash_events.dart';
import 'features/loading_splash/presentation/screens/index_screen.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
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
        BlocProvider<FetchingNetworkPCBloc>(
          create: (_) => sl<FetchingNetworkPCBloc>(),
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
        BlocProvider<AutoConnectionBloc>(
          create: (_) => sl<AutoConnectionBloc>(),
        ),
        BlocProvider<FetchStockBloc>(create: (_) => sl<FetchStockBloc>()),
        BlocProvider<StockListBloc>(create: (_) => sl<StockListBloc>()),
        BlocProvider<FilterOptionsBloc>(create: (_) => sl<FilterOptionsBloc>()),
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
      ],
      child: MaterialApp(
        title: 'RM-Mobile',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(fontFamily: "SourceSans3"),
        home: IndexScreen(),
      ),
    );
  }
}
