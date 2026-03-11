import '../repositories/home_repo.dart';

class LoadSavedConnectionInfo {
  final HomeRepo repository;

  LoadSavedConnectionInfo(this.repository);

  Future<SavedConnectionInfo> call() async {
    try {
      return await repository.loadSavedConnectionInfo();
    } catch (e) {
      return Future.error("Failed to load saved connection info: $e");
    }
  }
}
