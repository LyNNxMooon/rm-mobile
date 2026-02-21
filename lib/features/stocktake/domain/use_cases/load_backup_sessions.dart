import 'package:rmstock_scanner/entities/vos/backup_session_vo.dart';
import 'package:rmstock_scanner/entities/vos/device_metedata_vo.dart';
import 'package:rmstock_scanner/features/stocktake/domain/repositories/stocktake_repo.dart';
import 'package:rmstock_scanner/utils/device_meta_data_utils.dart';
import 'package:rmstock_scanner/utils/global_var_utils.dart';

class LoadBackupSessions {
  final StocktakeRepo repository;

  LoadBackupSessions(this.repository);

  Future<List<BackupSessionVO>> call() async {
    final ip = AppGlobals.instance.currentHostIp ?? "";
    final fullPath = AppGlobals.instance.currentPath ?? "";

    final DeviceMetadata mobileInfo = await DeviceMetaDataUtils.instance
        .getDeviceInformation();

    // Old setup disabled:
    // String? user;
    // String? pwd;
    // if (await NetworkCredentialsCheckUtils.instance
    //     .isRequiredNetworkCredentials(ipAddress: ip)) { ... }

    return repository.fetchBackupSessions(
      address: ip,
      fullPath: fullPath,
      username: AppGlobals.instance.defaultUserName,
      password: AppGlobals.instance.defaultPwd,
      mobileId: mobileInfo.deviceId,
    );
  }
}
