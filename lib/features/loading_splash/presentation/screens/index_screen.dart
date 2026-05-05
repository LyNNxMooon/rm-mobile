import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rmmobile/features/loading_splash/presentation/screens/loading_screen.dart';
import 'package:rmmobile/features/home_page/presentation/BLoC/dashboard_style_cubit.dart';

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
  bool _minimumTimeElapsed = false;
  Timer? _timeoutTimer;
  Timer? _minimumTimer;
  
  static const _minimumLoadingDuration = Duration(milliseconds: 2500);
  
  @override
  void initState() {
    super.initState();
    _loadingStartTime = DateTime.now();
    
    // Ensure loading screen shows for at least minimum duration
    _minimumTimer = Timer(_minimumLoadingDuration, () {
      if (mounted) {
        setState(() {
          _minimumTimeElapsed = true;
        });
      }
    });
  }
  
  @override
  void dispose() {
    _timeoutTimer?.cancel();
    _minimumTimer?.cancel();
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
          return const HomeScreen();
        }
        
        // Check if this is a loading state
        final bool isLoadingState = state is LoadingSplashInitial ||
            state is FetchingSavedPaths ||
            state is CheckingConnection ||
            state is SavedPathFetchingCompleted;
        
        // Also wait for dashboard style to be loaded
        return BlocBuilder<DashboardStyleCubit, String>(
          builder: (context, dashboardStyle) {
            final bool isDashboardStyleLoading = dashboardStyle.isEmpty;
            
            // Show loading screen if:
            // 1. Currently in a loading state, OR
            // 2. Minimum time hasn't elapsed yet, OR
            // 3. Dashboard style is still loading
            if (isLoadingState || !_minimumTimeElapsed || isDashboardStyleLoading) {
              return const LoadingScreen();
            } else {
              // Navigate to home for all other states (including ConnectionValid, errors, etc.)
              return const HomeScreen();
            }
          },
        );
      },
    );
  }
}
