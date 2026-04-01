import 'package:rmstock_scanner/entities/response/validate_response.dart';

abstract class LoadingSplashRepo {
  Future<List<Map<String, dynamic>>> getSavedPaths();
  Future<ValidateResponse> validateConnection({
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

  Future<void> deleteSavedPath(String path);
}
