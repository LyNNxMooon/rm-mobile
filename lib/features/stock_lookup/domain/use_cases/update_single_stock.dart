import 'package:rmmobile/features/stock_lookup/domain/repositories/stock_lookup_repo.dart';
import 'package:rmmobile/entities/response/stock_update_response.dart';
import 'package:rmmobile/entities/vos/pricing_rules.dart';

import '../../../../local_db/local_db_dao.dart';
import '../../../../utils/internet_connection_utils.dart';

class UpdateSingleStock {
  final StockLookupRepo repository;

  UpdateSingleStock(this.repository);

  Future<StockUpdateResponse> call({
    required int stockId,
    required String description,
    required double sell,
    String? custom1,
    String? custom2,
    String? longDesc,
    PricingRules? pricingRules,
  }) async {
    try {
      final ip = (await LocalDbDAO.instance.getHostIpAddress() ?? "").trim();
      final port =
          int.tryParse((await LocalDbDAO.instance.getHostPort() ?? "").trim());
      final apiKey = (await LocalDbDAO.instance.getApiKey() ?? "").trim();
      final shopfrontId =
          (await LocalDbDAO.instance.getShopfrontId() ?? "").trim();
      final shopfrontName =
          (await LocalDbDAO.instance.getShopfrontName() ?? "").trim();

      if (shopfrontName.isEmpty) {
        return Future.error(
          "Missing shopfront setup. Please reconnect to a host and shopfront.",
        );
      }

      await LocalDbDAO.instance.updateStockDetails(
        stockId: stockId,
        shopfront: shopfrontName,
        description: description,
        sell: sell,
        custom1: custom1,
        custom2: custom2,
        longDesc: longDesc,
        pricingRules: pricingRules,
      );

      final stockMap = await LocalDbDAO.instance.getStocksByIds(
        shopfront: shopfrontName,
        stockIds: [stockId],
      );
      final stock = stockMap[stockId];

      final payload = <String, dynamic>{
        'stock_id': stockId,
        if (stock != null) 'barcode': stock.barcode,
        if (stock != null) 'cost': stock.cost,
        if (stock != null) 'goods_tax': stock.goodsTax,
        if (stock != null) 'sales_tax': stock.salesTax,
        'description': description,
        'sell': sell,
        if (custom1 != null) 'custom1': custom1,
        if (custom2 != null) 'custom2': custom2,
        if (longDesc != null) 'longdesc': longDesc,
        if (pricingRules != null) 'pricing_rules': pricingRules.toJson(),
        'date_modified': DateTime.now().toIso8601String(),
      };

      final pendingId = await LocalDbDAO.instance.addPendingStockUpdate(
        shopfront: shopfrontName,
        stockId: stockId,
        payload: payload,
      );

      if (await InternetConnectionUtils.instance.checkInternetConnection()) {
        if (ip.isNotEmpty &&
            port != null &&
            apiKey.isNotEmpty &&
            shopfrontId.isNotEmpty) {
          try {
            // Old setup disabled:
            // - SMB credential checks
            // - local file write to outgoing stock update folder
            // await repository.sendSingleStockUpdate(...);

            final response = await repository.updateStockDetailsFromApi(
              ip: ip,
              port: port,
              apiKey: apiKey,
              shopfrontId: shopfrontId,
              stockId: stockId,
              description: description,
              sell: sell,
              custom1: custom1,
              custom2: custom2,
              longDesc: longDesc,
              pricingRules: pricingRules,
            );
            if (response.success) {
              await LocalDbDAO.instance.deletePendingStockUpdates([pendingId]);
              return response;
            }
          } catch (_) {}
        }
      }

      return StockUpdateResponse(
        success: true,
        message: "Saved locally. Will send when online.",
        updated: 1,
        missing: 0,
        skipped: 0,
      );
    } catch (error) {
      return StockUpdateResponse(
        success: true,
        message: "Saved locally. Will send when online.",
        updated: 1,
        missing: 0,
        skipped: 0,
      );
    }
  }
}
