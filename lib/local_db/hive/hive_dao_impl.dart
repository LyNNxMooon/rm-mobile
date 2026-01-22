import 'package:rmstock_scanner/entities/response/paginated_stock_response.dart';
import 'package:rmstock_scanner/entities/vos/counted_stock_vo.dart';
import 'package:rmstock_scanner/entities/vos/filter_criteria.dart';
import 'package:rmstock_scanner/local_db/local_db_dao.dart';
import '../../entities/vos/stock_vo.dart';

class HiveDAOImpl extends LocalDbDAO {
  @override
  Future<void> addNetworkPath(String path, String shopfront, String hostName) {
    // TODO: implement addNetworkPath
    throw UnimplementedError();
  }

  @override
  Future<void> clearStocksForShop(String shopfront) {
    // TODO: implement clearStocksForShop
    throw UnimplementedError();
  }

  @override
  Future<void> deleteAllStocktake() {
    // TODO: implement deleteAllStocktake
    throw UnimplementedError();
  }

  @override
  Future<void> deleteNetworkPath(String path) {
    // TODO: implement deleteNetworkPath
    throw UnimplementedError();
  }

  @override
  Future<void> deleteStocktake(int stockID, String shopfront) {
    // TODO: implement deleteStocktake
    throw UnimplementedError();
  }

  @override
  Future<List<Map<String, dynamic>>> getAllNetworkPaths() {
    // TODO: implement getAllNetworkPaths
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>?> getNetworkCredential({required String ip}) {
    // TODO: implement getNetworkCredential
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>?> getSingleNetworkPath(String targetPath) {
    // TODO: implement getSingleNetworkPath
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>?> getSinglePathByIp(String ipAddress) {
    // TODO: implement getSinglePathByIp
    throw UnimplementedError();
  }

  @override
  Future<StockVO?> getStockBySearch(String query, String shopfront) {
    // TODO: implement getStockBySearch
    throw UnimplementedError();
  }

  @override
  Future<List<Map<String, dynamic>>> getStocktakeList({
    required String shopfront,
  }) {
    // TODO: implement getStocktakeList
    throw UnimplementedError();
  }

  @override
  Future<List<Map<String, dynamic>>> getSyncedStocks(String shopfront) {
    // TODO: implement getSyncedStocks
    throw UnimplementedError();
  }

  @override
  Future<List<CountedStockVO>> getUnsyncedStocks(String shopfront) {
    // TODO: implement getUnsyncedStocks
    throw UnimplementedError();
  }

  @override
  Future<void> initDB() {
    // TODO: implement initDB
    throw UnimplementedError();
  }

  @override
  Future<void> insertStocks(List<StockVO> stocks, String shopfront) {
    // TODO: implement insertStocks
    throw UnimplementedError();
  }

  @override
  Future<void> markStockAsSynced(List<int> stockIds, String shopfront) {
    // TODO: implement markStockAsSynced
    throw UnimplementedError();
  }

  @override
  Future<void> removeNetworkCredential({required String ip}) {
    // TODO: implement removeNetworkCredential
    throw UnimplementedError();
  }

  @override
  Future<void> saveCountedStock(Map<String, dynamic> stockData) {
    // TODO: implement saveCountedStock
    throw UnimplementedError();
  }

  @override
  Future<void> saveNetworkCredential({
    required String ip,
    required String username,
    required String password,
  }) {
    // TODO: implement saveNetworkCredential
    throw UnimplementedError();
  }

  @override
  Future<PaginatedStockResult> searchAndSortStocks({
    required String shopfront,
    required String query,
    required String filterColumn,
    required String sortColumn,
    required bool ascending,
    required int limit,
    required int offset,
    FilterCriteria? filters
  }) {
    // TODO: implement searchAndSortStocks
    throw UnimplementedError();
  }

  @override
  Future<void> updatePathByIp({
    required String ip,
    required String selectedPath,
  }) {
    // TODO: implement updatePathByIp
    throw UnimplementedError();
  }

  @override
  Future<void> updateShopfrontByIp({
    required String ip,
    required String selectedShopfront,
  }) {
    // TODO: implement updateShopfrontByIp
    throw UnimplementedError();
  }

  @override
  Future<List<String>> getDistinctValues(String columnName,String shopfront) {
    // TODO: implement getDistinctValues
    throw UnimplementedError();
  }

  @override
  Future<String?> getAppConfig(String key) {
    // TODO: implement getAppConfig
    throw UnimplementedError();
  }

  @override
  Future<void> saveAppConfig(String key, String value) {
    // TODO: implement saveAppConfig
    throw UnimplementedError();
  }
}
