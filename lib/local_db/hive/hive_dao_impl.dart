import 'package:rmstock_scanner/entities/response/paginated_stock_response.dart';
import 'package:rmstock_scanner/entities/vos/counted_stock_vo.dart';
import 'package:rmstock_scanner/entities/vos/filter_criteria.dart';
//import 'package:rmstock_scanner/local_db/local_db_dao.dart';
import '../../entities/vos/stock_vo.dart';

class HiveDAOImpl
//extends LocalDbDAO
{
  Future<void> addNetworkPath(String path, String shopfront, String hostName) =>
      throw UnimplementedError();

  Future<void> clearStocksForShop(String shopfront) {
    throw UnimplementedError();
  }

  Future<void> deleteAllStocktake() {
    throw UnimplementedError();
  }

  Future<void> deleteNetworkPath(String path) {
    throw UnimplementedError();
  }

  Future<void> deleteStocktake(int stockID, String shopfront) {
    throw UnimplementedError();
  }

  Future<List<Map<String, dynamic>>> getAllNetworkPaths() {
    throw UnimplementedError();
  }

  Future<Map<String, dynamic>?> getNetworkCredential({required String ip}) {
    throw UnimplementedError();
  }

  Future<Map<String, dynamic>?> getSingleNetworkPath(String targetPath) {
    throw UnimplementedError();
  }

  Future<Map<String, dynamic>?> getSinglePathByIp(String ipAddress) {
    throw UnimplementedError();
  }

  Future<StockVO?> getStockBySearch(String query, String shopfront) {
    throw UnimplementedError();
  }

  Future<List<Map<String, dynamic>>> getStocktakeList({
    required String shopfront,
  }) {
    throw UnimplementedError();
  }

  Future<List<Map<String, dynamic>>> getSyncedStocks(String shopfront) {
    throw UnimplementedError();
  }

  Future<List<CountedStockVO>> getUnsyncedStocks(String shopfront) {
    throw UnimplementedError();
  }

  Future<void> initDB() {
    throw UnimplementedError();
  }

  Future<void> insertStocks(List<StockVO> stocks, String shopfront) {
    throw UnimplementedError();
  }

  Future<void> markStockAsSynced(List<int> stockIds, String shopfront) {
    throw UnimplementedError();
  }

  Future<void> removeNetworkCredential({required String ip}) {
    throw UnimplementedError();
  }

  Future<void> saveCountedStock(Map<String, dynamic> stockData) {
    throw UnimplementedError();
  }

  Future<void> saveNetworkCredential({
    required String ip,
    required String username,
    required String password,
  }) {
    throw UnimplementedError();
  }

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

  Future<void> updatePathByIp({
    required String ip,
    required String selectedPath,
  }) {
    throw UnimplementedError();
  }

  Future<void> updateShopfrontByIp({
    required String ip,
    required String selectedShopfront,
  }) {
    throw UnimplementedError();
  }

  Future<List<String>> getDistinctValues(String columnName, String shopfront) {
    throw UnimplementedError();
  }

  Future<String?> getAppConfig(String key) {
    throw UnimplementedError();
  }

  Future<void> saveAppConfig(String key, String value) {
    throw UnimplementedError();
  }

  Future<Map<num, StockVO>> getStocksByIds({
    required String shopfront,
    required List<num> stockIds,
  }) {
    throw UnimplementedError();
  }

  Future<List<Map<String, dynamic>>> getStocktakeHistoryItems({
    required String sessionId,
    required String shopfront,
  }) {
    throw UnimplementedError();
  }

  Future<List<Map<String, dynamic>>> getStocktakeHistorySessions({
    required String shopfront,
  }) {
    throw UnimplementedError();
  }

  Future<void> saveStocktakeHistorySession({
    required String sessionId,
    required String shopfront,
    required String mobileDeviceId,
    required String mobileDeviceName,
    required int totalStocks,
    required DateTime dateStarted,
    required DateTime dateEnded,
    required List<CountedStockVO> items,
  }) {
    throw UnimplementedError();
  }

  Future<int> cleanupHistoryByRetention() {
    throw UnimplementedError();
  }

  Future<int> deleteHistoryOlderThan(DateTime cutoffUtc) {
    throw UnimplementedError();
  }

  Future<int> getHistoryRetentionDays() {
    throw UnimplementedError();
  }

  Future<void> setHistoryRetentionDays(int days) {
    throw UnimplementedError();
  }

  Future<StockVO?> getStockByIDSearch(String query, String shopfront) {
    throw UnimplementedError();
  }

  Future<void> updateStockQuantity({
    required int stockId,
    required String shopfront,
    required num newQuantity,
  }) {
    throw UnimplementedError();
  }

  Future<int> getUnsyncedStocksCount(String shopfront) {
    throw UnimplementedError();
  }

  Future<List<CountedStockVO>> getUnsyncedStocksPaged({
    required String shopfront,
    required int limit,
    required int offset,
  }) {
    throw UnimplementedError();
  }
}
