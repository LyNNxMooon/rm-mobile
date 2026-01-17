abstract class LoadingSplashRepo {
  Future<List<Map<String, dynamic>>> getSavedPaths();

  Future<void> checksConnection(
    String ip,
    String path,
    String? userName,
    String? pwd,
  );
}
