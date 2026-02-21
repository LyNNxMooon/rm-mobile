import 'package:rmstock_scanner/entities/vos/counted_stock_vo.dart';
import 'package:rmstock_scanner/entities/vos/device_metedata_vo.dart';
import 'package:rmstock_scanner/features/stocktake/domain/repositories/stocktake_repo.dart';
import 'package:rmstock_scanner/local_db/local_db_dao.dart';
import 'package:rmstock_scanner/utils/device_meta_data_utils.dart';
import 'package:rmstock_scanner/utils/global_var_utils.dart';
import 'package:rmstock_scanner/utils/internet_connection_utils.dart';

class BackupStocktake {
  final StocktakeRepo repository;

  BackupStocktake(this.repository);

  Future<void> call() async {
    try {
      final ip = AppGlobals.instance.currentHostIp ?? "";
      final fullPath = AppGlobals.instance.currentPath ?? "";
      final shopfront = AppGlobals.instance.shopfront ?? "";

      if (await InternetConnectionUtils.instance.checkInternetConnection()) {
        final List<CountedStockVO> unsyncedStocks = await LocalDbDAO.instance
            .getUnsyncedStocks(shopfront);

        // Old setup disabled:
        // String? user;
        // String? pwd;
        // if (await NetworkCredentialsCheckUtils.instance
        //     .isRequiredNetworkCredentials(ipAddress: ip)) { ... }

        final DeviceMetadata mobileInfo = await DeviceMetaDataUtils.instance
            .getDeviceInformation();

        await repository.backupToLanFodler(
          address: ip,
          fullPath: fullPath,
          mobileID: mobileInfo.deviceId,
          mobileName: mobileInfo.name,
          shopfrontName: AppGlobals.instance.shopfront ?? "",
          username: null,
          password: null,
          dataToSync: unsyncedStocks,
        );
      } else {
        return Future.error("Please connect to a network!");
      }
    } catch (error) {
      return Future.error(error);
    }
  }
}
