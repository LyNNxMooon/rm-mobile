import 'package:rmstock_scanner/entities/response/paginated_stock_response.dart';
import 'package:rmstock_scanner/entities/vos/counted_stock_vo.dart';
import 'package:rmstock_scanner/entities/vos/filter_criteria.dart';
import 'package:rmstock_scanner/local_db/local_db_dao.dart';
import '../../entities/vos/stock_vo.dart';

class HiveDAOImpl extends LocalDbDAO {
  @override
  Future<void> addNetworkPath(String path, String shopfront, String hostName) =>
      throw UnimplementedError();

  @override
  Future<void> clearStocksForShop(String shopfront) {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteAllStocktake() {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteNetworkPath(String path) {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteStocktake(int stockID, String shopfront) {
    throw UnimplementedError();
  }

  @override
  Future<List<Map<String, dynamic>>> getAllNetworkPaths() {
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>?> getNetworkCredential({required String ip}) {
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>?> getSingleNetworkPath(String targetPath) {
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>?> getSinglePathByIp(String ipAddress) {
    throw UnimplementedError();
  }

  @override
  Future<StockVO?> getStockBySearch(String query, String shopfront) {
    throw UnimplementedError();
  }

  @override
  Future<List<Map<String, dynamic>>> getStocktakeList({
    required String shopfront,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<Map<String, dynamic>>> getSyncedStocks(String shopfront) {
    throw UnimplementedError();
  }

  @override
  Future<List<CountedStockVO>> getUnsyncedStocks(String shopfront) {
    throw UnimplementedError();
  }

  @override
  Future<void> initDB() {
    throw UnimplementedError();
  }

  @override
  Future<void> insertStocks(List<StockVO> stocks, String shopfront) {
    throw UnimplementedError();
  }

  @override
  Future<void> markStockAsSynced(List<int> stockIds, String shopfront) {
    throw UnimplementedError();
  }

  @override
  Future<void> removeNetworkCredential({required String ip}) {
    throw UnimplementedError();
  }

  @override
  Future<void> saveCountedStock(Map<String, dynamic> stockData) {
    throw UnimplementedError();
  }

  @override
  Future<void> saveNetworkCredential({
    required String ip,
    required String username,
    required String password,
  }) {
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
    FilterCriteria? filters,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> updatePathByIp({
    required String ip,
    required String selectedPath,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> updateShopfrontByIp({
    required String ip,
    required String selectedShopfront,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<String>> getDistinctValues(String columnName, String shopfront) {
    throw UnimplementedError();
  }

  @override
  Future<String?> getAppConfig(String key) {
    throw UnimplementedError();
  }

  @override
  Future<void> saveAppConfig(String key, String value) {
    throw UnimplementedError();
  }
}
