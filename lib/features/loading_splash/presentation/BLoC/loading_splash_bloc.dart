import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/use_cases/check_path_connection.dart';
import '../../domain/use_cases/delete_saved_path.dart';
import '../../domain/use_cases/fetch_saved_paths.dart';
import 'loading_splash_events.dart';
import 'loading_splash_states.dart';

class NetworkSavedPathValidationBloc
    extends Bloc<LoadingSplashEvents, LoadingSplashStates> {
  final FetchSavedPaths fetchSavedPaths;
  final CheckPathConnection checkPathConnection;
  final DeleteSavedPath deleteSavedPath;

  NetworkSavedPathValidationBloc({
    required this.fetchSavedPaths,
    required this.checkPathConnection,
    required this.deleteSavedPath,
  }) : super(LoadingSplashInitial()) {
    on<FetchSavedPathsEvent>(_onFetchSavedPathEvent);
    on<ConnectionCheckingEvent>(_onConnectionCheckingEvent);
    on<DeleteSavedPathEvent>(_onDeleteSavedPathEvent);
  }

  Future<void> _onFetchSavedPathEvent(
    FetchSavedPathsEvent event,
    Emitter<LoadingSplashStates> emit,
  ) async {
    emit(FetchingSavedPaths());
    try {
      final list = await fetchSavedPaths();

      if (list.isEmpty) {
        emit(ErrorFetchingSavedPaths("No saved paths found!"));
      } else {
        emit(SavedPathFetchingCompleted(list));
      }

    } catch (error) {
      emit(ErrorFetchingSavedPaths("Error fetching saved paths: $error"));
    }
  }

  Future<void> _onConnectionCheckingEvent(
    ConnectionCheckingEvent event,
    Emitter<LoadingSplashStates> emit,
  ) async {
    emit(CheckingConnection());
    try {
      // Add timeout to prevent infinite waiting
      final bool passed = await checkPathConnection(event.path)
          .timeout(
            const Duration(seconds: 20),
            onTimeout: () {
              return false;
            },
          );

      if (passed) {
        emit(ConnectionValid());
      } else {
        emit(ErrorCheckingConnection("Cannot connect to the saved path!"));
      }
    } catch (error) {
      emit(ErrorCheckingConnection("Error checking connection: $error"));
    }
  }

  Future<void> _onDeleteSavedPathEvent(
    DeleteSavedPathEvent event,
    Emitter<LoadingSplashStates> emit,
  ) async {
    try {
      await deleteSavedPath(event.path);
      add(FetchSavedPathsEvent());
    } catch (error) {
      emit(ErrorFetchingSavedPaths("Error deleting saved path: $error"));
    }
  }
}
