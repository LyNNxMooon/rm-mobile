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

      // Detect conflicts before sending
      await LocalDbDAO.instance.detectPendingStockConflicts(shopfront);
      
      // Re-fetch to get updated conflict status
      final refreshedPending =
          await LocalDbDAO.instance.getPendingStockUpdates(shopfront);
      
      // Split into conflicting and non-conflicting
      final conflicting = refreshedPending.where((e) => e.hasConflict).toList();
      final toSend = refreshedPending.where((e) => !e.hasConflict).toList();
      
      if (toSend.isEmpty) {
        return StockUpdateResponse(
          success: false,
          message: "${conflicting.length} update(s) have conflicts. Please review them.",
          updated: 0,
          missing: 0,
          skipped: conflicting.length,
        );
      }

      final List<int> pendingIds = [];
      final List<Map<String, dynamic>> items = [];
      final String now = DateTime.now().toIso8601String();

      for (final entry in toSend) {
        pendingIds.add(entry.id);
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

        final Map<String, dynamic> itemData = {
          "stock_id": stockId,
          "description": description,
          "sell": sell,
          "date_modified": now,
        };

        if (custom1 != null) {
          itemData["custom1"] = custom1;
        }
        if (custom2 != null) {
          itemData["custom2"] = custom2;
        }
        if (pricingRules != null) {
          itemData["pricing_rules"] = pricingRules.toJson();
        }

        items.add(itemData);
      }

      final response = await repository.updateStockDetailsBatchFromApi(
        ip: ip,
        port: port,
        apiKey: apiKey,
        shopfrontId: shopfrontId,
        items: items,
      );

      if (response.success && response.skipped == 0) {
        await LocalDbDAO.instance.deletePendingStockUpdates(pendingIds);
      } else {
        for (final id in pendingIds) {
          await LocalDbDAO.instance.setPendingStockUpdateError(
            id: id,
            errorMessage: response.message,
          );
        }
      }

      final int skipped = response.skipped > 0
          ? response.skipped
          : (response.success ? 0 : pendingIds.length);

      return StockUpdateResponse(
        success: response.success && skipped == 0,
        message: response.success && skipped == 0
            ? "Pending stock updates sent."
            : "Some stock updates failed to send.",
        updated: response.updated,
        missing: response.missing,
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
