import 'dart:typed_data';

import '../../../../entities/response/paginated_stock_response.dart';
import '../../../../entities/response/picture_upload_response.dart';
import '../../../../entities/response/stock_update_response.dart';
import '../../../../entities/vos/filter_criteria.dart';
import '../../../../entities/vos/pricing_rules.dart';
import '../../../../entities/vos/search_mode.dart';
import '../../../../entities/vos/stock_vo.dart';
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
    SearchMode searchMode,
  });

  Future<Map<String, List<String>>> getFilterOptions(String shopfront);
  Future<StockVO?> resolvePackageComponentStock({
    required int stockId,
    String? barcode,
  });
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

  Future<PictureUploadResponse> uploadStockImage({
    required String ip,
    required int port,
    required String shopfrontId,
    required int stockId,
    required String apiKey,
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

  Future<StockUpdateResponse> updateStockDetailsFromApi({
    required String ip,
    required int port,
    required String apiKey,
    required String shopfrontId,
    required int stockId,
    required String description,
    required double sell,
    String? custom1,
    String? custom2,
    PricingRules? pricingRules,
  });

  Future<StockUpdateResponse> updateStockDetailsBatchFromApi({
    required String ip,
    required int port,
    required String apiKey,
    required String shopfrontId,
    required List<Map<String, dynamic>> items,
  });

  Future<String?> getShopfrontName();

  Future<String?> getShopfrontId();

  Future<String?> getAppConfig(String key);

  Future<void> saveAppConfig(String key, String value);
}
