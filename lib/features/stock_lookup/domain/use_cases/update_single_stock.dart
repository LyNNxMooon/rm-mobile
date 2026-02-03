import 'package:rmstock_scanner/features/stock_lookup/domain/repositories/stock_lookup_repo.dart';

import '../../../../entities/vos/device_metedata_vo.dart';
import '../../../../local_db/local_db_dao.dart';
import '../../../../utils/device_meta_data_utils.dart';
import '../../../../utils/global_var_utils.dart';
import '../../../../utils/internet_connection_utils.dart';
import '../../../../utils/network_credentials_check_utils.dart';

class UpdateSingleStock {
  final StockLookupRepo repository;

  UpdateSingleStock(this.repository);

  Future<void> call({
    required int stockId,
    required String description,
    required double sell,
  }) async {
    try {
      final ip = AppGlobals.instance.currentHostIp ?? "";
      final fullPath = AppGlobals.instance.currentPath ?? "";
      final shopfront = AppGlobals.instance.shopfront ?? "";

      if (await InternetConnectionUtils.instance.checkInternetConnection()) {
        String? user;
        String? pwd;

        if (await NetworkCredentialsCheckUtils.instance
            .isRequiredNetworkCredentials(ipAddress: ip)) {
          final Map<String, dynamic>? savedCred =
          await LocalDbDAO.instance.getNetworkCredential(ip: ip);

          user = savedCred?['username'];
          pwd = savedCred?['password'];
        }

        final DeviceMetadata mobileInfo =
        await DeviceMetaDataUtils.instance.getDeviceInformation();

        await repository.sendSingleStockUpdate(
          address: ip,
          fullPath: fullPath,
          username: user,
          password: pwd,
          mobileID: mobileInfo.deviceId,
          mobileName: mobileInfo.name,
          shopfrontName: shopfront,
          stockId: stockId,
          description: description,
          sell: sell,
        );
      } else {
        return Future.error("Please connect to a network!");
      }
    } catch (error) {
      return Future.error(error);
    }
  }
}
