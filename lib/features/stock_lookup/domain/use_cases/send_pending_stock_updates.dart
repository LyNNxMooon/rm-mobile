import '../../../../entities/response/stock_update_response.dart';
import '../../../../entities/vos/pricing_rules.dart';
import '../../../../local_db/local_db_dao.dart';
import '../../../../utils/internet_connection_utils.dart';
import '../repositories/stock_lookup_repo.dart';

class SendPendingStockUpdates {
  final StockLookupRepo repository;

  SendPendingStockUpdates(this.repository);

  Future<StockUpdateResponse> call(String shopfront) async {
    try {
      if (!await InternetConnectionUtils.instance.checkInternetConnection()) {
        return Future.error("Please connect to a network!");
      }

      final ip = (await LocalDbDAO.instance.getHostIpAddress() ?? "").trim();
      final port =
          int.tryParse((await LocalDbDAO.instance.getHostPort() ?? "").trim());
      final apiKey = (await LocalDbDAO.instance.getApiKey() ?? "").trim();
      final shopfrontId =
          (await LocalDbDAO.instance.getShopfrontId() ?? "").trim();

      if (ip.isEmpty || port == null || apiKey.isEmpty || shopfrontId.isEmpty) {
        return Future.error(
          "Missing host/shopfront/api setup. Please reconnect first.",
        );
      }

      final pending =
          await LocalDbDAO.instance.getPendingStockUpdates(shopfront);
      if (pending.isEmpty) {
        return StockUpdateResponse(
          success: true,
          message: "No pending stock updates.",
          updated: 0,
          missing: 0,
          skipped: 0,
        );
      }

      final List<int> sentIds = [];
      int updated = 0;
      int skipped = 0;

      for (final entry in pending) {
        final payload = entry.payload;
        final int stockId = (payload['stock_id'] as num?)?.toInt() ??
            (payload['stockId'] as num?)?.toInt() ??
            entry.stockId;
        final String description = (payload['description'] as String?) ?? '';
        final double sell = (payload['sell'] as num?)?.toDouble() ?? 0.0;
        final String? custom1 = payload['custom1'] as String?;
        final String? custom2 = payload['custom2'] as String?;
        final PricingRules? pricingRules = _parsePricingRules(
          payload['pricing_rules'],
        );

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
          pricingRules: pricingRules,
        );

        if (response.success) {
          updated += 1;
          sentIds.add(entry.id);
        } else {
          skipped += 1;
          await LocalDbDAO.instance.setPendingStockUpdateError(
            id: entry.id,
            errorMessage: response.message,
          );
        }
      }

      if (sentIds.isNotEmpty) {
        await LocalDbDAO.instance.deletePendingStockUpdates(sentIds);
      }

      return StockUpdateResponse(
        success: skipped == 0,
        message: skipped == 0
            ? "Pending stock updates sent."
            : "Some stock updates failed to send.",
        updated: updated,
        missing: 0,
        skipped: skipped,
      );
    } catch (e) {
      return Future.error("Failed to send pending stock updates: $e");
    }
  }

  PricingRules? _parsePricingRules(dynamic payload) {
    if (payload is Map<String, dynamic>) {
      return PricingRules.fromJson(payload);
    }
    if (payload is Map) {
      return PricingRules.fromJson(Map<String, dynamic>.from(payload));
    }
    return null;
  }
}
