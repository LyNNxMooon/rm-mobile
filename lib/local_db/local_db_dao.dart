import 'package:rmstock_scanner/entities/vos/counted_stock_vo.dart';
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
  Future<StockVO?> getStockBySearch(String query, String shopfront);
  Future<PaginatedStockResult> searchAndSortStocks({
    required String shopfront,
    required String query,
    required String filterColumn,
    required String sortColumn,
    required bool ascending,
    required int limit,
    required int offset,
  });
  Future<List<String>> getDistinctValues(String columnName);

  // Setters to save data
  Future<void> saveCountedStock(Map<String, dynamic> stockData);

  Future<void> saveNetworkCredential({
    required String ip,
    required String username,
    required String password,
  });

  Future<void> addNetworkPath(String path, String shopfront, String hostName);
  Future<void> insertStocks(List<StockVO> stocks, String shopfront);

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

  //Removing data
  Future<void> removeNetworkCredential({required String ip});
  Future<void> deleteNetworkPath(String path);
  Future<void> deleteStocktake(int stockID, String shopfront);
  Future<void> deleteAllStocktake();
  Future<void> clearStocksForShop(String shopfront);
}
