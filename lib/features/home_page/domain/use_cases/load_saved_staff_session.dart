import 'package:rmstock_scanner/features/home_page/domain/repositories/home_repo.dart';

class LoadSavedStaffSession {
  final HomeRepo repository;

  LoadSavedStaffSession(this.repository);

  Future<bool> call() async {
    try {
      return await repository.loadSavedStaffSession();
    } catch (error) {
      return Future.error(error);
    }
  }
}
