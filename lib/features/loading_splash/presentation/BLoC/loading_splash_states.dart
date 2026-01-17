abstract class LoadingSplashStates {}

class LoadingSplashInitial extends LoadingSplashStates {}

class FetchingSavedPaths extends LoadingSplashStates {}

class SavedPathFetchingCompleted extends LoadingSplashStates {
  final List<Map<String, dynamic>> paths;

  SavedPathFetchingCompleted(this.paths);
}

class ErrorFetchingSavedPaths extends LoadingSplashStates {
  final String message;

  ErrorFetchingSavedPaths(this.message);
}

class CheckingConnection extends LoadingSplashStates {}

class ConnectionValid extends LoadingSplashStates {}

class ErrorCheckingConnection extends LoadingSplashStates {
  final String message;

  ErrorCheckingConnection(this.message);
}
