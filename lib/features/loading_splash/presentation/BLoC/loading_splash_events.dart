abstract class LoadingSplashEvents {}

class FetchSavedPathsEvent extends LoadingSplashEvents {}

class ConnectionCheckingEvent extends LoadingSplashEvents {
  final String path;

  ConnectionCheckingEvent(this.path);
}
