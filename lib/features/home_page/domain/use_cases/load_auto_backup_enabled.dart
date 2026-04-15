import 'package:rmmobile/features/home_page/domain/repositories/home_repo.dart';

class LoadAutoBackupEnabled {
  final HomeRepo repository;
  LoadAutoBackupEnabled(this.repository);

  Future<bool> call() => repository.getAutoBackupEnabled();
}
