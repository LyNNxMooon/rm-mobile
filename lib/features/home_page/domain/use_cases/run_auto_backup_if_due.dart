import 'package:rmstock_scanner/features/home_page/domain/repositories/home_repo.dart';
import 'package:rmstock_scanner/features/stocktake/domain/use_cases/backup_stocktake.dart';

class RunAutoBackupIfDue {
  final HomeRepo repository;
  final BackupStocktake backupStocktake;

  RunAutoBackupIfDue({
    required this.repository,
    required this.backupStocktake,
  });

  Future<bool> call({bool force = false}) async {
    final enabled = await repository.getAutoBackupEnabled();
    if (!enabled) return false;

    final last = await repository.getLastAutoBackupAt();
    if (!force && last != null) {
      final elapsed = DateTime.now().toUtc().difference(last.toUtc());
      if (elapsed < const Duration(hours: 24)) {
        return false;
      }
    }

    await backupStocktake();
    await repository.setLastAutoBackupAt(DateTime.now().toUtc());
    return true;
  }
}
