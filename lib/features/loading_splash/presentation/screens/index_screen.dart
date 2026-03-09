import 'dart:async';

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
  DateTime? _loadingStartTime;
  bool _timeoutReached = false;
  Timer? _timeoutTimer;
  
  @override
  void initState() {
    super.initState();
  }
  
  @override
  void dispose() {
    _timeoutTimer?.cancel();
    super.dispose();
  }
  
  void _checkAndStartTimeout(LoadingSplashStates state) {
    final bool isLoadingState = state is FetchingSavedPaths ||
        state is CheckingConnection ||
        state is SavedPathFetchingCompleted;
    
    if (isLoadingState) {
      // Start tracking loading time if not already tracking
      if (_loadingStartTime == null) {
        _loadingStartTime = DateTime.now();
        
        // Set a 30-second timeout
        _timeoutTimer?.cancel();
        _timeoutTimer = Timer(const Duration(seconds: 30), () {
          if (mounted) {
            setState(() {
              _timeoutReached = true;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Connection check timed out. Opening in offline mode.'),
                duration: Duration(seconds: 3),
                backgroundColor: Colors.orange,
              ),
            );
          }
        });
      }
    } else {
      // Not in loading state, reset timer
      _loadingStartTime = null;
      _timeoutReached = false;
      _timeoutTimer?.cancel();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NetworkSavedPathValidationBloc, LoadingSplashStates>(
      builder: (context, state) {
        // Check and manage timeout
        _checkAndStartTimeout(state);
        
        // If timeout reached, show home screen regardless of state
        if (_timeoutReached) {
          return HomeScreen();
        }
        
        // Normal flow - show loading screen only during active loading states
        if (state is FetchingSavedPaths ||
            state is CheckingConnection ||
            state is SavedPathFetchingCompleted) {
          return LoadingScreen();
        } else {
          // Navigate to home for all other states (including ConnectionValid, errors, etc.)
          return HomeScreen();
        }
      },
    );
  }
}
