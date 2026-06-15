import 'package:rmmobile/features/home_page/domain/repositories/home_repo.dart';

class LoadDashboardWhiteTheme {
  final HomeRepo repository;
  LoadDashboardWhiteTheme(this.repository);

  Future<bool> call() => repository.getDashboardWhiteThemeEnabled();
}
