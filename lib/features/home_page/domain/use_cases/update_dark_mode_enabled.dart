import 'package:rmmobile/features/home_page/domain/repositories/home_repo.dart';

class UpdateDarkModeEnabled {
  final HomeRepo repository;
  UpdateDarkModeEnabled(this.repository);

  Future<void> call(bool enabled) => repository.setDarkModeEnabled(enabled);
}
