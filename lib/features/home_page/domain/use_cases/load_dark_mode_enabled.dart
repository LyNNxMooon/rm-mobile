import 'package:rmstock_scanner/features/home_page/domain/repositories/home_repo.dart';

class LoadDarkModeEnabled {
  final HomeRepo repository;
  LoadDarkModeEnabled(this.repository);

  Future<bool> call() => repository.getDarkModeEnabled();
}
