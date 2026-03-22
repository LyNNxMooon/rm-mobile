import '../repositories/stock_lookup_repo.dart';

class SeedStockSyncTimestamp {
  final StockLookupRepo repository;

  SeedStockSyncTimestamp(this.repository);

  Future<void> call() async {
    try {
      final shopfrontId = (await repository.getShopfrontId()) ?? '';
      if (shopfrontId.trim().isEmpty) return;
      final syncKey = 'stock_sync_timestamp_$shopfrontId';
      final lastSync = await repository.getAppConfig(syncKey);
      if (lastSync == null || lastSync.trim().isEmpty) {
        await repository.saveAppConfig(
          syncKey,
          DateTime.now().toIso8601String(),
        );
      }
    } catch (error) {
      return Future.error(error);
    }
  }
}
