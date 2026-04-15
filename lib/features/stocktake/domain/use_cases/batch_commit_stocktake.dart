import 'package:rmmobile/entities/vos/counted_stock_vo.dart';
import 'package:rmmobile/entities/vos/device_metedata_vo.dart';
import 'package:rmmobile/features/stocktake/domain/entities/batch_commit_entities.dart';
import 'package:rmmobile/features/stocktake/domain/entities/stocktake_audit_entities.dart';
import 'package:rmmobile/features/stocktake/domain/repositories/stocktake_repo.dart';
import 'package:rmmobile/local_db/local_db_dao.dart';
import 'package:rmmobile/utils/device_meta_data_utils.dart';
import 'package:rmmobile/utils/global_var_utils.dart';
import 'package:rmmobile/utils/internet_connection_utils.dart';
import 'package:rmmobile/utils/network_credentials_check_utils.dart';

/// Maximum number of items to send per batch
const int kBatchSize = 5000;

/// Use case for processing stocktake commits in batches.
/// 
/// This orchestrates the flow:
/// 1. Get all unsynced items from local DB
/// 2. Split into batches of [kBatchSize]
/// 3. For each batch: initcheck → get audits → final commit
/// 4. Mark batch items as synced after successful commit
/// 5. Repeat for remaining batches
class BatchCommitStocktake {
  final StocktakeRepo repository;

  BatchCommitStocktake(this.repository);

  /// Returns the list of batches to process
  Future<List<StocktakeBatch>> prepareBatches() async {
    final shopfront = AppGlobals.instance.shopfront ?? "";
    final allItems = await LocalDbDAO.instance.getStocktakeItemsToCommit(shopfront);

    if (allItems.isEmpty) {
      return [];
    }

    final List<StocktakeBatch> batches = [];
    final totalBatches = (allItems.length / kBatchSize).ceil();

    for (int i = 0; i < totalBatches; i++) {
      final start = i * kBatchSize;
      final end = (start + kBatchSize > allItems.length) 
          ? allItems.length 
          : start + kBatchSize;
      
      batches.add(StocktakeBatch(
        batchIndex: i,
        totalBatches: totalBatches,
        items: allItems.sublist(start, end),
      ));
    }

    return batches;
  }

  /// Performs init check for a single batch
  /// Returns the audit items for this batch
  Future<List<AuditWithStockVO>> initCheckBatch(StocktakeBatch batch) async {
    if (!await InternetConnectionUtils.instance.checkInternetConnection()) {
      throw Exception("Please connect to a network!");
    }

    String ip = AppGlobals.instance.currentHostIp ?? "";
    final fullPath = AppGlobals.instance.currentPath ?? "";

    if (ip.trim().isEmpty) {
      ip = (await LocalDbDAO.instance.getHostIpAddress() ?? "").trim();
      if (ip.isNotEmpty) {
        AppGlobals.instance.currentHostIp = ip;
      }
    }

    String? user;
    String? pwd;

    if (await NetworkCredentialsCheckUtils.instance.isRequiredNetworkCredentials(ipAddress: ip)) {
      final savedCred = await LocalDbDAO.instance.getNetworkCredential(ip: ip);
      user = savedCred?['username'];
      pwd = savedCred?['password'];
    }

    final DeviceMetadata mobileInfo = await DeviceMetaDataUtils.instance.getDeviceInformation();

    final response = await repository.commitToLanFolder(
      address: ip,
      fullPath: fullPath,
      mobileID: mobileInfo.deviceId,
      mobileName: mobileInfo.name,
      shopfrontName: AppGlobals.instance.shopfront ?? "",
      username: user,
      password: pwd,
      dataToSync: batch.items,
    );

    if (!response.success) {
      throw Exception(response.message);
    }

    // Build audit list with stock details
    final List<AuditWithStockVO> auditsWithStock = [];
    final shopfront = AppGlobals.instance.shopfront ?? "";
    
    for (final audit in response.data) {
      final stock = await repository.fetchStockDetailsByID(
        audit.stockId.toInt(),
        shopfront,
      );
      auditsWithStock.add(AuditWithStockVO(audit: audit, stock: stock));
    }

    return auditsWithStock;
  }

  /// Performs final commit for a single batch
  /// Marks items as synced after successful commit
  Future<void> commitBatch(
    StocktakeBatch batch,
    List<AuditWithStockVO> auditData,
  ) async {
    if (!await InternetConnectionUtils.instance.checkInternetConnection()) {
      throw Exception("Please connect to a network!");
    }

    final ip = AppGlobals.instance.currentHostIp ?? "";
    final fullPath = AppGlobals.instance.currentPath ?? "";
    final shopfront = AppGlobals.instance.shopfront ?? "";

    String? user;
    String? pwd;

    if (await NetworkCredentialsCheckUtils.instance.isRequiredNetworkCredentials(ipAddress: ip)) {
      final savedCred = await LocalDbDAO.instance.getNetworkCredential(ip: ip);
      user = savedCred?['username'];
      pwd = savedCred?['password'];
    }

    final DeviceMetadata mobileInfo = await DeviceMetaDataUtils.instance.getDeviceInformation();

    final response = await repository.finalSendingStocktaketoRM(
      address: ip,
      fullPath: fullPath,
      mobileID: mobileInfo.deviceId,
      mobileName: mobileInfo.name,
      shopfrontName: shopfront,
      username: user,
      password: pwd,
      dataToSync: batch.items,
      auditData: auditData,
    );

    if (!response.success) {
      throw Exception(response.message);
    }

    // Mark batch items as synced (only after successful commit)
    // Pass auditData so adjusted quantities are saved to history
    await _markBatchAsSynced(batch, shopfront, mobileInfo, auditData);
  }

  Future<void> _markBatchAsSynced(
    StocktakeBatch batch,
    String shopfront,
    DeviceMetadata mobileInfo,
    List<AuditWithStockVO> auditData,
  ) async {
    // Apply audit adjustments to get final quantities
    List<CountedStockVO> adjustedData = List.from(batch.items);

    // Apply audit movements to quantities (same logic as finalSendingStocktaketoRM)
    if (auditData.isNotEmpty) {
      for (var auditRecord in auditData) {
        final audit = auditRecord.audit;

        int index = adjustedData.indexWhere(
          (s) => s.stockID == audit.stockId,
        );

        if (index != -1) {
          final currentStock = adjustedData[index];
          final newQuantity = currentStock.quantity + audit.movement;

          adjustedData[index] = CountedStockVO(
            stockID: currentStock.stockID,
            stocktakeDate: currentStock.stocktakeDate,
            quantity: newQuantity,
            dateModified: DateTime.now(),
            barcode: currentStock.barcode,
            description: currentStock.description,
            inStock: currentStock.inStock,
          );
        }
      }
    }

    final now = DateTime.now();
    String pad(int v) => v.toString().padLeft(2, '0');
    final timestamp = "${now.year}${pad(now.month)}${pad(now.day)}"
        "${pad(now.hour)}${pad(now.minute)}${pad(now.second)}_batch${batch.batchIndex}";

    final sessionId = "${mobileInfo.deviceId}_stocktake_$timestamp";

    DateTime dateStarted = now;
    DateTime dateEnded = now;
    if (adjustedData.isNotEmpty) {
      dateStarted = adjustedData
          .map((e) => e.stocktakeDate)
          .reduce((a, b) => a.isBefore(b) ? a : b);

      dateEnded = adjustedData
          .map((e) => e.dateModified)
          .reduce((a, b) => a.isAfter(b) ? a : b);
    }

    // Save history for this batch
    await LocalDbDAO.instance.saveStocktakeHistorySession(
      sessionId: sessionId,
      shopfront: shopfront,
      mobileDeviceId: mobileInfo.deviceId,
      mobileDeviceName: mobileInfo.name,
      totalStocks: adjustedData.length,
      dateStarted: dateStarted,
      dateEnded: dateEnded,
      items: adjustedData,
    );

    // Mark items as synced (removes from stocktake table)
    final stockIds = adjustedData.map((s) => s.stockID).toList();
    await LocalDbDAO.instance.markStockAsSynced(stockIds, shopfront);
  }
}
