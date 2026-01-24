import 'package:rmstock_scanner/entities/vos/device_metedata_vo.dart';
import 'package:rmstock_scanner/features/stocktake/domain/repositories/stocktake_repo.dart';
import 'package:rmstock_scanner/features/stocktake/models/stocktake_model.dart';

import '../../../../entities/vos/counted_stock_vo.dart';
import '../../../../local_db/local_db_dao.dart';
import '../../../../utils/device_meta_data_utils.dart';
import '../../../../utils/global_var_utils.dart';
import '../../../../utils/internet_connection_utils.dart';
import '../../../../utils/network_credentials_check_utils.dart';

class SendFinalStocktakeToRm {
  final StocktakeRepo repository;

  SendFinalStocktakeToRm(this.repository);

  Future<void> call(List<AuditWithStockVO> auditData) async {
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
          user = savedCred?['password'];
        }

        final DeviceMetadata mobileInfo = await DeviceMetaDataUtils.instance
            .getDeviceInformation();

        await repository.finalSendingStocktaketoRM(
          address: ip,
          fullPath: fullPath,
          mobileID: mobileInfo.deviceId,
          mobileName: mobileInfo.name,
          shopfrontName: AppGlobals.instance.shopfront ?? "",
          username: user,
          password: pwd,
          dataToSync: unsyncedStocks,
          auditData: auditData,
        );

        // We will store to back up synced stocks table later here

        final List<int> stockIds = unsyncedStocks
            .map((s) => s.stockID)
            .toList();

        await LocalDbDAO.instance.markStockAsSynced(stockIds, shopfront);
      } else {
        return Future.error("Please connect to a network!");
      }
    } catch (error) {
      return Future.error(error);
    }
  }
}
