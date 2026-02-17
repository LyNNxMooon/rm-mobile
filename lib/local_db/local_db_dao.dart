import 'package:rmstock_scanner/entities/response/stock_search_resposne.dart';
import 'package:rmstock_scanner/entities/vos/backup_stocktake_item_vo.dart';
import 'package:rmstock_scanner/entities/vos/counted_stock_vo.dart';
import 'package:rmstock_scanner/entities/vos/filter_criteria.dart';
import 'package:rmstock_scanner/entities/vos/stock_vo.dart';

import '../entities/response/paginated_stock_response.dart';

abstract class LocalDbDAO {
  static LocalDbDAO? _instance;
  static LocalDbDAO get instance {
    if (_instance == null) {
      throw Exception("LocalDbDAO not initialized. Call init() in main.dart");
    }
    return _instance!;
  }

  static void configure(LocalDbDAO implementation) {
    _instance = implementation;
  }

  Future<void> initDB();

  //Getter to get data
  Future<Map<String, dynamic>?> getNetworkCredential({required String ip});
  Future<List<Map<String, dynamic>>> getAllNetworkPaths();
  Future<Map<String, dynamic>?> getSingleNetworkPath(String targetPath);
  Future<List<Map<String, dynamic>>> getStocktakeList({
    required String shopfront,
  });
  Future<Map<String, dynamic>?> getSinglePathByIp(String ipAddress);
  Future<List<CountedStockVO>> getUnsyncedStocks(String shopfront);
  Future<List<Map<String, dynamic>>> getSyncedStocks(String shopfront);
  Future<StockSearchResult> getStockBySearch(String query, String shopfront);
  Future<PaginatedStockResult> searchAndSortStocks({
    required String shopfront,
    required String query,
    required String filterColumn,
    required String sortColumn,
    required bool ascending,
    required int limit,
    required int offset,
    FilterCriteria? filters,
  });
  Future<List<String>> getDistinctValues(String columnName, String shopfront);
  Future<String?> getAppConfig(String key);
  Future<String?> getHostIpAddress();
  Future<String?> getHostPort();
  Future<String?> getApiKey();
  Future<String?> getHostName();
  Future<String?> getShopfrontId();
  Future<String?> getShopfrontName();
  Future<String?> getDeviceId();
  Future<Map<num, StockVO>> getStocksByIds({
    required String shopfront,
    required List<num> stockIds,
  });
  Future<List<Map<String, dynamic>>> getStocktakeHistorySessions({
    required String shopfront,
  });
  Future<List<Map<String, dynamic>>> getStocktakeHistoryItems({
    required String sessionId,
    required String shopfront,
  });
  Future<int> getHistoryRetentionDays();
  Future<StockVO?> getStockByIDSearch(String query, String shopfront);
  Future<int> getUnsyncedStocksCount({
    required String shopfront,
    String? query,
  });
  Future<List<CountedStockVO>> getUnsyncedStocksPaged({
    required String shopfront,
    required int limit,
    required int offset,
    String? query,
  });

  Future<List<StockVO>> getStocksByBarcode(String barcode, String shopfront);

  // Setters to save data
  Future<void> saveCountedStock(Map<String, dynamic> stockData);

  Future<void> saveNetworkCredential({
    required String ip,
    required String username,
    required String password,
  });

  Future<void> addNetworkPath(String path, String shopfront, String hostName);
  Future<void> insertStocks(List<StockVO> stocks, String shopfront);
  Future<void> saveAppConfig(String key, String value);
  Future<void> saveHostIpAddress(String hostIpAddress);
  Future<void> saveHostPort(String hostPort);
  Future<void> saveApiKey(String apiKey);
  Future<void> saveHostName(String hostName);
  Future<void> saveShopfrontId(String shopfrontId);
  Future<void> saveShopfrontName(String shopfrontName);
  Future<void> saveDeviceId(String deviceId);
  Future<void> saveStocktakeHistorySession({
    required String sessionId,
    required String shopfront,
    required String mobileDeviceId,
    required String mobileDeviceName,
    required int totalStocks,
    required DateTime dateStarted,
    required DateTime dateEnded,
    required List<CountedStockVO> items,
  });
  Future<void> setHistoryRetentionDays(int days);
  Future<void> restoreStocktakeFromBackup({
    required String shopfront,
    required List<BackupStocktakeItemVO> items,
  });

  //Update Data
  Future<void> updateShopfrontByIp({
    required String ip,
    required String selectedShopfront,
  });
  Future<void> updatePathByIp({
    required String ip,
    required String selectedPath,
  });
  Future<void> markStockAsSynced(List<int> stockIds, String shopfront);
  Future<int> cleanupHistoryByRetention();
  Future<void> updateStockQuantity({
    required int stockId,
    required String shopfront,
    required num newQuantity,
  });

  //Removing data
  Future<void> removeNetworkCredential({required String ip});
  Future<void> deleteNetworkPath(String path);
  Future<void> deleteStocktake(int stockID, String shopfront);
  Future<void> deleteAllStocktake();
  Future<void> clearStocksForShop(String shopfront);
  Future<int> deleteHistoryOlderThan(DateTime cutoffUtc);
}
