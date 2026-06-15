import 'package:rmmobile/features/home_page/domain/repositories/home_repo.dart';

class UpdateDashboardWhiteTheme {
  final HomeRepo repository;
  UpdateDashboardWhiteTheme(this.repository);

  Future<void> call(bool enabled) =>
      repository.setDashboardWhiteThemeEnabled(enabled);
}
