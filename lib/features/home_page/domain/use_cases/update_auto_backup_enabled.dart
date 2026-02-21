import 'package:rmstock_scanner/features/home_page/domain/repositories/home_repo.dart';

class UpdateAutoBackupEnabled {
  final HomeRepo repository;
  UpdateAutoBackupEnabled(this.repository);

  Future<void> call(bool enabled) => repository.setAutoBackupEnabled(enabled);
}
