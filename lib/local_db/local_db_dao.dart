import 'package:rmstock_scanner/entities/response/stock_search_resposne.dart';
import 'package:rmstock_scanner/entities/vos/backup_stocktake_item_vo.dart';
import 'package:rmstock_scanner/entities/vos/counted_stock_vo.dart';
import 'package:rmstock_scanner/entities/vos/customer_vo.dart';
import 'package:rmstock_scanner/entities/vos/pending_customer_update_vo.dart';
import 'package:rmstock_scanner/entities/vos/pending_stock_update_vo.dart';
import 'package:rmstock_scanner/entities/vos/filter_criteria.dart';
import 'package:rmstock_scanner/entities/vos/search_mode.dart';
import 'package:rmstock_scanner/entities/vos/pricing_rules.dart';
import 'package:rmstock_scanner/entities/vos/stock_vo.dart';

import '../entities/response/paginated_stock_response.dart';
import '../entities/response/paginated_customer_response.dart';

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
    SearchMode searchMode = SearchMode.partial,
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

  // Customer methods
  Future<PaginatedCustomerResult> searchAndSortCustomers({
    required String shopfront,
    required String query,
    required String filterColumn,
    required String sortColumn,
    required bool ascending,
    required int limit,
    required int offset,
    FilterCriteria? filters,
    SearchMode searchMode = SearchMode.partial,
  });

  Future<List<String>> getDistinctCustomerValues(
    String columnName,
    String shopfront,
  );

  Future<CustomerVO?> getCustomerById(int customerId, String shopfront);

  Future<int> getNextCustomerId(String shopfront);

  Future<int> getNextCustomerAddressId(String shopfront);

  Future<String> getNextNumericBarcode(String shopfront);

  Future<bool> checkBarcodeExists(String barcode, String shopfront);

  // Customer transactions
  Future<void> replaceCustomerTransactions({
    required String shopfront,
    required int customerId,
    required List<Map<String, dynamic>> purchases,
    required List<Map<String, dynamic>> credit,
    required List<Map<String, dynamic>> invoices,
    required List<Map<String, dynamic>> ivPay,
    required List<Map<String, dynamic>> laybys,
    required List<Map<String, dynamic>> lbPay,
    required List<Map<String, dynamic>> cso,
    required List<Map<String, dynamic>> soQuote,
    required List<Map<String, dynamic>> soPay,
  });

  Future<List<Map<String, dynamic>>> getCustomerPurchases({
    required String shopfront,
    required int customerId,
    int limit,
  });

  Future<List<Map<String, dynamic>>> getCustomerCredit({
    required String shopfront,
    required int customerId,
    int limit,
  });

  Future<List<Map<String, dynamic>>> getCustomerInvoices({
    required String shopfront,
    required int customerId,
    int limit,
  });

  Future<List<Map<String, dynamic>>> getCustomerIvPay({
    required String shopfront,
    required int customerId,
    int limit,
  });

  Future<List<Map<String, dynamic>>> getCustomerLaybys({
    required String shopfront,
    required int customerId,
    int limit,
  });

  Future<List<Map<String, dynamic>>> getCustomerLbPay({
    required String shopfront,
    required int customerId,
    int limit,
  });

  Future<List<Map<String, dynamic>>> getCustomerCso({
    required String shopfront,
    required int customerId,
    int limit,
  });

  Future<List<Map<String, dynamic>>> getCustomerSoQuote({
    required String shopfront,
    required int customerId,
    int limit,
  });

  Future<List<Map<String, dynamic>>> getCustomerSoPay({
    required String shopfront,
    required int customerId,
    int limit,
  });

  // Setters to save data
  Future<void> saveCountedStock(Map<String, dynamic> stockData);

  Future<void> saveNetworkCredential({
    required String ip,
    required String username,
    required String password,
  });

  Future<void> addNetworkPath(String path, String shopfront, String hostName);
  Future<void> insertStocks(List<StockVO> stocks, String shopfront);
  Future<void> insertCustomers(List<CustomerVO> customers, String shopfront);
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

  Future<void> updateStockDetails({
    required int stockId,
    required String shopfront,
    required String description,
    required double sell,
    String? custom1,
    String? custom2,
    PricingRules? pricingRules,
  });

  Future<int> addPendingStockUpdate({
    required String shopfront,
    required int stockId,
    required Map<String, dynamic> payload,
  });
  Future<int> getPendingStockUpdatesCount(String shopfront);
  Future<List<PendingStockUpdateVO>> getPendingStockUpdates(String shopfront);
  Future<void> deletePendingStockUpdates(List<int> ids);
  Future<void> applyPendingStockUpdates(String shopfront);

  Future<int> addPendingCustomerUpdate({
    required String shopfront,
    required int customerId,
    required String action,
    required Map<String, dynamic> payload,
  });
  Future<int> getPendingCustomerUpdatesCount(String shopfront);
  Future<List<PendingCustomerUpdateVO>> getPendingCustomerUpdates(
    String shopfront, {
    String? action,
    bool? conflictOnly,
  });
  Future<void> deletePendingCustomerUpdates(List<int> ids);
  Future<void> setPendingCustomerConflict(List<int> ids, bool hasConflict);
  Future<void> updatePendingCustomerPayload({
    required int id,
    required int customerId,
    required Map<String, dynamic> payload,
  });
  Future<void> applyPendingCustomerUpdates(String shopfront);

  //Removing data
  Future<void> removeNetworkCredential({required String ip});
  Future<void> deleteNetworkPath(String path);
  Future<void> deleteStocktake(int stockID, String shopfront);
  Future<void> deleteAllStocktake();
  Future<void> clearCustomersForShop(String shopfront);
  Future<void> clearStocksForShop(String shopfront);
  Future<int> deleteHistoryOlderThan(DateTime cutoffUtc);
}
