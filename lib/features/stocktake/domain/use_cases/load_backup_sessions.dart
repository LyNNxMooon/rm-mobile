import 'package:rmstock_scanner/entities/vos/backup_session_vo.dart';
import 'package:rmstock_scanner/entities/vos/device_metedata_vo.dart';
import 'package:rmstock_scanner/features/stocktake/domain/repositories/stocktake_repo.dart';
import 'package:rmstock_scanner/local_db/local_db_dao.dart';
import 'package:rmstock_scanner/utils/device_meta_data_utils.dart';
import 'package:rmstock_scanner/utils/global_var_utils.dart';
import 'package:rmstock_scanner/utils/network_credentials_check_utils.dart';

class LoadBackupSessions {
  final StocktakeRepo repository;

  LoadBackupSessions(this.repository);

  Future<List<BackupSessionVO>> call() async {
    final ip = AppGlobals.instance.currentHostIp ?? "";
    final fullPath = AppGlobals.instance.currentPath ?? "";

    final DeviceMetadata mobileInfo = await DeviceMetaDataUtils.instance
        .getDeviceInformation();

    String? user;
    String? pwd;

    if (await NetworkCredentialsCheckUtils.instance
        .isRequiredNetworkCredentials(ipAddress: ip)) {
      final saved = await LocalDbDAO.instance.getNetworkCredential(ip: ip);
      user = saved?['username'];
      pwd = saved?['password'];
    }

    return repository.fetchBackupSessions(
      address: ip,
      fullPath: fullPath,
      username: user ?? AppGlobals.instance.defaultUserName,
      password: pwd ?? AppGlobals.instance.defaultPwd,
      mobileId: mobileInfo.deviceId,
    );
  }
}
