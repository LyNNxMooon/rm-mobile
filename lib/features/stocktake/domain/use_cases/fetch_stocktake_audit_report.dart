import 'package:rmstock_scanner/entities/vos/device_metedata_vo.dart';
import 'package:rmstock_scanner/features/stocktake/domain/repositories/stocktake_repo.dart';
import 'package:rmstock_scanner/features/stocktake/models/stocktake_model.dart';
import 'package:rmstock_scanner/local_db/local_db_dao.dart';
import 'package:rmstock_scanner/utils/device_meta_data_utils.dart';
import 'package:rmstock_scanner/utils/global_var_utils.dart';
import 'package:rmstock_scanner/utils/internet_connection_utils.dart';
import 'package:rmstock_scanner/utils/network_credentials_check_utils.dart';

class FetchStocktakeAuditReport {
  final StocktakeRepo repository;

  FetchStocktakeAuditReport(this.repository);

  Stream<AuditSyncStatus> call() async* {
    try {
      final ip = AppGlobals.instance.currentHostIp ?? "";

      if (await InternetConnectionUtils.instance.checkInternetConnection()) {
        final DeviceMetadata mobileInfo = await DeviceMetaDataUtils.instance
            .getDeviceInformation();

        String? finalUser;
        String? finalPwd;

        if (await NetworkCredentialsCheckUtils.instance
            .isRequiredNetworkCredentials(ipAddress: ip)) {
          final credentials = await LocalDbDAO.instance.getNetworkCredential(
            ip: ip,
          );
          finalUser = credentials?['username'] as String?;
          finalPwd = credentials?['password'] as String?;
        }

        yield* repository.fetchStocktakeAuditReport(
          ipAddress: ip,
          fullPath: AppGlobals.instance.currentPath ?? "",
          username: finalUser,
          password: finalPwd,
          mobileID: mobileInfo.deviceId,
          shopfront: AppGlobals.instance.shopfront ?? "",
        );
      } else {
        yield* Stream.error("Please connect to a network!");
      }
    } catch (error) {
      yield* Stream.error(error);
    }
  }
}
