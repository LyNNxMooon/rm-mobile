import 'package:rmstock_scanner/entities/vos/device_metedata_vo.dart';
import 'package:rmstock_scanner/features/stocktake/domain/repositories/stocktake_repo.dart';

import '../../../../entities/vos/counted_stock_vo.dart';
import '../../../../local_db/local_db_dao.dart';
import '../../../../utils/device_meta_data_utils.dart';
import '../../../../utils/global_var_utils.dart';
import '../../../../utils/internet_connection_utils.dart';
import '../../../../utils/network_credentials_check_utils.dart';

class CommitStocktake {
  final StocktakeRepo repository;

  CommitStocktake(this.repository);

  Future<void> call() async {
    try {
      final ip = AppGlobals.instance.currentHostIp ?? "";
      final fullPath = AppGlobals.instance.currentPath ?? "";
      final shopfront = AppGlobals.instance.shopfront ?? "";

      if (await InternetConnectionUtils.instance.checkInternetConnection()) {
        final List<CountedStockVO> unsyncedStocks = await LocalDbDAO.instance
            .getUnsyncedStocks(shopfront);

        String? user;
        String? pwd;

        if (await NetworkCredentialsCheckUtils.instance
            .isRequiredNetworkCredentials(ipAddress: ip)) {
          final Map<String, dynamic>? savedCred = await LocalDbDAO.instance
              .getNetworkCredential(ip: ip);

          user = savedCred?['username'];
          pwd = savedCred?['password'];
        }

        final DeviceMetadata mobileInfo = await DeviceMetaDataUtils.instance
            .getDeviceInformation();
            

        final response = await repository.commitToLanFolder(
          address: ip,
          fullPath: fullPath,
          mobileID: mobileInfo.deviceId,
          mobileName: mobileInfo.name,
          shopfrontName: AppGlobals.instance.shopfront ?? "",
          username: user,
          password: pwd,
          dataToSync: unsyncedStocks,
        );

        if (!response.success) {
          return Future.error(response.message);
        }

      } else {
        return Future.error("Please connect to a network!");
      }
    } catch (error) {
      return Future.error(error);
    }
  }
}
