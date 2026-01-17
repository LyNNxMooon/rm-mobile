import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rmstock_scanner/features/loading_splash/presentation/screens/loading_screen.dart';

import '../../../home_page/presentation/screens/home_screen.dart';
import '../BLoC/loading_splash_bloc.dart';
import '../BLoC/loading_splash_states.dart';

class IndexScreen extends StatefulWidget {
  const IndexScreen({super.key});

  @override
  State<IndexScreen> createState() => _IndexScreenState();
}

class _IndexScreenState extends State<IndexScreen> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NetworkSavedPathValidationBloc, LoadingSplashStates>(
      builder: (context, state) {
        if (state is FetchingSavedPaths ||
            state is CheckingConnection ||
            state is SavedPathFetchingCompleted) {
          return LoadingScreen();
        } else {
          return HomeScreen();
        }
      },
    );
  }
}
