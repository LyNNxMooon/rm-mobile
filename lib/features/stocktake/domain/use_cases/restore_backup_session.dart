import 'package:rmstock_scanner/entities/vos/backup_session_vo.dart';
import 'package:rmstock_scanner/features/stocktake/domain/repositories/stocktake_repo.dart';
import 'package:rmstock_scanner/local_db/local_db_dao.dart';
import 'package:rmstock_scanner/utils/global_var_utils.dart';
import 'package:rmstock_scanner/utils/network_credentials_check_utils.dart';

class RestoreBackupSession {
  final StocktakeRepo repository;

  RestoreBackupSession(this.repository);

  Future<void> call(BackupSessionVO session) async {
    final ip = AppGlobals.instance.currentHostIp ?? "";
    final fullPath = AppGlobals.instance.currentPath ?? "";
    final shopfront = AppGlobals.instance.shopfront ?? "";

    String? user;
    String? pwd;

    if (await NetworkCredentialsCheckUtils.instance
        .isRequiredNetworkCredentials(ipAddress: ip)) {
      final saved = await LocalDbDAO.instance.getNetworkCredential(ip: ip);
      user = saved?['username'];
      pwd = saved?['password'];
    }

    final items = await repository.fetchBackupItems(
      address: ip,
      fullPath: fullPath,
      username: user ?? AppGlobals.instance.defaultUserName,
      password: pwd ?? AppGlobals.instance.defaultPwd,
      fileName: session.fileName,
    );

    await LocalDbDAO.instance.restoreStocktakeFromBackup(
      shopfront: shopfront,
      items: items,
    );
  }
}
