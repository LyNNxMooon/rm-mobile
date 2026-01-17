import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rmstock_scanner/features/home_page/presentation/BLoC/home_screen_bloc.dart';
import 'package:rmstock_scanner/features/stock_lookup/presentation/BLoC/stock_lookup_bloc.dart';
import 'package:rmstock_scanner/features/stocktake/presentation/BLoC/stocktake_bloc.dart';
import 'package:rmstock_scanner/utils/dependency_injection_utils.dart';

import 'features/loading_splash/presentation/BLoC/loading_splash_bloc.dart';
import 'features/loading_splash/presentation/BLoC/loading_splash_events.dart';
import 'features/loading_splash/presentation/screens/index_screen.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
