import '../repositories/home_repo.dart';

class LoadSavedStaffCredentials {
  final HomeRepo repository;

  LoadSavedStaffCredentials(this.repository);

  Future<SavedStaffCredentials> call() async {
    try {
      return await repository.loadSavedStaffCredentials();
    } catch (e) {
      return Future.error("Failed to load saved staff credentials: $e");
    }
  }
}
