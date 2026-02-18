import 'dart:typed_data';

import '../../../../entities/response/paginated_stock_response.dart';
import '../../../../entities/vos/filter_criteria.dart';
import '../entities/sync_status.dart';

abstract class StockLookupRepo {
  Stream<SyncStatus> fetchAndSaveStocks(String ipAddress);

  Future<PaginatedStockResult> fetchStocksDynamic({
    required String shopfront,
    required String query,
    required String filterColumn,
    required String sortColumn,
    required bool ascending,
    required int page,
    FilterCriteria? filters,
    int pageSize,
  });

  Future<Map<String, List<String>>> getFilterOptions(String shopfront);
  Future<String?> fetchAndCacheThumbnailPath({
    required String address,
    required String fullPath,
    required String? username,
    required String? password,
    required String shopfrontName,
    required String pictureFileName,
    bool forceRefresh = false,
  });

  Future<String?> fetchAndCacheFullImagePath({
    required String address,
    required String fullPath,
    required String? username,
    required String? password,
    required String shopfrontName,
    required String pictureFileName,
    bool forceRefresh = false,
  });

  Future<void> uploadStockImage({
    required String address,
    required String fullPath,
    required String? username,
    required String? password,
    required String fileName,
    required Uint8List jpgBytes,
  });

  Future sendSingleStockUpdate({
    required String address,
    required String fullPath,
    required String? username,
    required String? password,
    required String mobileName,
    required String mobileID,
    required String shopfrontName,
    required int stockId,
    required String description,
    required double sell,
  });
}
