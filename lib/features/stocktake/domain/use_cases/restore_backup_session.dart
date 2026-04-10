import 'package:rmmobile/entities/vos/backup_session_vo.dart';
import 'package:rmmobile/features/stocktake/domain/repositories/stocktake_repo.dart';
import 'package:rmmobile/utils/global_var_utils.dart';
import 'package:rmmobile/local_db/local_db_dao.dart';

class RestoreBackupSession {
  final StocktakeRepo repository;

  RestoreBackupSession(this.repository);

  Future<void> call(BackupSessionVO session) async {
    final ip = AppGlobals.instance.currentHostIp ?? "";
    final fullPath = AppGlobals.instance.currentPath ?? "";
    final shopfront = AppGlobals.instance.shopfront ?? "";

    // Old setup disabled:
    // String? user;
    // String? pwd;
    // if (await NetworkCredentialsCheckUtils.instance
    //     .isRequiredNetworkCredentials(ipAddress: ip)) { ... }

    final items = await repository.fetchBackupItems(
      address: ip,
      fullPath: fullPath,
      username: AppGlobals.instance.defaultUserName,
      password: AppGlobals.instance.defaultPwd,
      fileName: session.fileName,
    );

    await LocalDbDAO.instance.restoreStocktakeFromBackup(
      shopfront: shopfront,
      items: items,
    );
  }
}
