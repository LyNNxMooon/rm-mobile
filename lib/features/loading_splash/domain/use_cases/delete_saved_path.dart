import '../repositories/loading_splash_repo.dart';

class DeleteSavedPath {
  final LoadingSplashRepo repository;

  DeleteSavedPath(this.repository);

  Future<void> call(String path) async {
    try {
      await repository.deleteSavedPath(path);
    } catch (e) {
      return Future.error("Failed to delete saved path: $e");
    }
  }
}
