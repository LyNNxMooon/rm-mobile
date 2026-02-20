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
          pwd = savedCred?['password'];
        }

        final DeviceMetadata mobileInfo = await DeviceMetaDataUtils.instance
            .getDeviceInformation();

        final response = await repository.finalSendingStocktaketoRM(
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

        if (!response.success) {
          return Future.error(response.message);
        }

        final now = DateTime.now();
        String pad(int v) => v.toString().padLeft(2, '0');
        final String timestamp =
            "${now.year}"
            "${pad(now.month)}"
            "${pad(now.day)}"
            "${pad(now.hour)}"
            "${pad(now.minute)}"
            "${pad(now.second)}";

        final String sessionId = "${mobileInfo.deviceId}_stocktake_$timestamp";

        DateTime dateStarted = now;
        DateTime dateEnded = now;
        if (unsyncedStocks.isNotEmpty) {
          dateStarted = unsyncedStocks
              .map((e) => e.stocktakeDate)
              .reduce((a, b) => a.isBefore(b) ? a : b);

          dateEnded = unsyncedStocks
              .map((e) => e.dateModified)
              .reduce((a, b) => a.isAfter(b) ? a : b);
        }

        List<CountedStockVO> adjustedData = List.from(unsyncedStocks);

        if (auditData.isNotEmpty) {
          for (var auditRecord in auditData) {
            final audit = auditRecord.audit;

            int index = adjustedData.indexWhere(
              (s) => s.stockID == audit.stockId,
            );

            if (index != -1) {
              final currentStock = adjustedData[index];

              final newQuantity = currentStock.quantity + audit.movement;

              adjustedData[index] = CountedStockVO(
                stockID: currentStock.stockID,
                stocktakeDate: currentStock.stocktakeDate,
                quantity: newQuantity,
                dateModified: DateTime.now(),
                isSynced: currentStock.isSynced,
                barcode: currentStock.barcode,
                description: currentStock.description,
                inStock: currentStock.inStock
              );
            }
          }
        }

        await LocalDbDAO.instance.saveStocktakeHistorySession(
          sessionId: sessionId,
          shopfront: shopfront,
          mobileDeviceId: mobileInfo.deviceId,
          mobileDeviceName: mobileInfo.name,
          totalStocks: adjustedData.length,
          dateStarted: dateStarted,
          dateEnded: dateEnded,
          items: adjustedData,
        );

        final List<int> stockIds = adjustedData
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
