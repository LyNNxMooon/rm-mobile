import 'package:rmstock_scanner/features/stock_lookup/domain/repositories/stock_lookup_repo.dart';
import 'package:rmstock_scanner/entities/response/stock_update_response.dart';

import '../../../../local_db/local_db_dao.dart';
import '../../../../utils/internet_connection_utils.dart';

class UpdateSingleStock {
  final StockLookupRepo repository;

  UpdateSingleStock(this.repository);

  Future<StockUpdateResponse> call({
    required int stockId,
    required String description,
    required double sell,
  }) async {
    try {
      final ip = (await LocalDbDAO.instance.getHostIpAddress() ?? "").trim();
      final port = int.tryParse((await LocalDbDAO.instance.getHostPort() ?? "").trim());
      final apiKey = (await LocalDbDAO.instance.getApiKey() ?? "").trim();
      final shopfrontId = (await LocalDbDAO.instance.getShopfrontId() ?? "").trim();

      if (await InternetConnectionUtils.instance.checkInternetConnection()) {
        if (ip.isEmpty || port == null || apiKey.isEmpty || shopfrontId.isEmpty) {
          return Future.error(
            "Missing host/shopfront/api setup. Please reconnect first.",
          );
        }

        // Old setup disabled:
        // - SMB credential checks
        // - local file write to outgoing stock update folder
        // await repository.sendSingleStockUpdate(...);

        return await repository.updateStockDetailsFromApi(
          ip: ip,
          port: port,
          apiKey: apiKey,
          shopfrontId: shopfrontId,
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
