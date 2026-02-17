abstract class LoadingSplashRepo {
  Future<List<Map<String, dynamic>>> getSavedPaths();
  Future<bool> validateConnection({
    required String ip,
    required int port,
    required String apiKey,
  });

  Future<void> checksConnection(
    String ip,
    String path,
    String? userName,
    String? pwd,
  );
}
