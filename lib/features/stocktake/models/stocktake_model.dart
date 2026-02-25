import 'package:flutter/material.dart';
import 'package:rmstock_scanner/entities/response/stock_search_resposne.dart';
import 'package:rmstock_scanner/entities/response/stocktake_commit_response.dart';
import 'package:rmstock_scanner/entities/response/stocktake_initcheck_response.dart';
import 'package:rmstock_scanner/entities/response/stocktake_limit_response.dart';
import 'package:rmstock_scanner/entities/vos/audit_item_vo.dart';
import 'package:rmstock_scanner/entities/vos/backup_session_vo.dart';
import 'package:rmstock_scanner/entities/vos/backup_stocktake_item_vo.dart';
import 'package:rmstock_scanner/entities/vos/counted_stock_vo.dart';
import 'package:rmstock_scanner/network/data_agent/data_agent_impl.dart';

import '../../../entities/vos/stock_vo.dart';
import '../../../local_db/local_db_dao.dart';
import '../domain/repositories/stocktake_repo.dart';

class StocktakeModel implements StocktakeRepo {
  //Data manipulation can be done here (E.g. substituting data for null values returned from API)
  StocktakeInitcheckResponse? _lastInitcheckResponse;
  DateTime? _lastStocktakeApiCallAt;

  // Protect initcheck/commit endpoints from back-to-back calls (429 rate limit).
  static const Duration _stocktakeApiMinGap = Duration(seconds: 2);

  Future<void> _enforceStocktakeApiCooldown() async {
    final DateTime now = DateTime.now();
    if (_lastStocktakeApiCallAt != null) {
      final Duration elapsed = now.difference(_lastStocktakeApiCallAt!);
      if (elapsed < _stocktakeApiMinGap) {
        await Future.delayed(_stocktakeApiMinGap - elapsed);
      }
    }
    _lastStocktakeApiCallAt = DateTime.now();
  }

  @override
  Future<StockSearchResult> fetchStockDetails(
    String query,
    String shopfront,
  ) async {
    try {
      return LocalDbDAO.instance.getStockBySearch(query, shopfront);
    } catch (error) {
      return Future.error(error);
    }
  }

  @override
  Future<StockVO?> fetchStockDetailsByID(int id, String shopfront) async {
    try {
      String stockId = id.toString();

      return LocalDbDAO.instance.getStockByIDSearch(stockId, shopfront);
    } on Exception catch (error) {
      return Future.error(error);
    }
  }

  @override
  Future<StocktakeInitcheckResponse> commitToLanFolder({
    required String address,
    required String fullPath,
    required String? username,
    required String? password,
    required String mobileName,
    required String mobileID,
    required String shopfrontName,
    required List<CountedStockVO> dataToSync,
  }) async {
    try {
      // Old setup disabled:
      // final String jsonContent = _StocktakeJsonBuilder.buildJson(...);
      // final String fileName = "${mobileID}_initCheck_$timestamp.json.gz";
      // return LanNetworkServiceImpl.instance.writeStocktakeDataToSharedFolder(...);

      final int resolvedPort =
          int.tryParse(
            (await LocalDbDAO.instance.getHostPort() ?? "").trim(),
          ) ??
          5000;
      final String resolvedApiKey =
          (await LocalDbDAO.instance.getApiKey() ?? "").trim();
      final String resolvedShopfrontId =
          (await LocalDbDAO.instance.getShopfrontId() ?? "").trim();

      if (address.trim().isEmpty ||
          resolvedApiKey.isEmpty ||
          resolvedShopfrontId.isEmpty) {
        throw Exception("Missing host/shopfront setup for init check.");
      }

      final DateTime dateStarted = dataToSync.isNotEmpty
          ? dataToSync
                .map((e) => e.stocktakeDate)
                .reduce((a, b) => a.isBefore(b) ? a : b)
          : DateTime.now();

      final body = <String, dynamic>{
        "mobile_device_id": mobileID,
        "mobile_device_name": mobileName,
        "date_started": dateStarted.toIso8601String(),
        "data": dataToSync.map((e) => {"stock_id": e.stockID}).toList(),
      };

      await _enforceStocktakeApiCooldown();
      final response = await DataAgentImpl.instance.stocktakeInitCheck(
        address,
        resolvedPort,
        resolvedShopfrontId,
        resolvedApiKey,
        body,
      );
      _lastInitcheckResponse = response;
      return response;
    } on Exception catch (error) {
      return Future.error(error);
    }
  }

  @override
  Future<StocktakeCommitResponse> finalSendingStocktaketoRM({
    required String address,
    required String fullPath,
    required String? username,
    required String? password,
    required String mobileName,
    required String mobileID,
    required String shopfrontName,
    required List<CountedStockVO> dataToSync,
    required List<AuditWithStockVO> auditData,
  }) async {
    try {
      List<CountedStockVO> adjustedData = List.from(dataToSync);

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
              isSynced: currentStock.isSynced,
              barcode: currentStock.barcode,
              description: currentStock.description,
              inStock: currentStock.inStock,
            );

            // await LocalDbDAO.instance.updateStockQuantity(
            //   stockId: (currentStock.stockID).toInt(),
            //   shopfront: shopfrontName,
            //   newQuantity: newQuantity,
            // );
          }
        }
      }

      // Old setup disabled:
      // final String jsonContent = _StocktakeJsonBuilder.buildJson(...);
      // final String fileName = "${mobileID}_stocktake_$timestamp.json.gz";
      // return LanNetworkServiceImpl.instance.writeStocktakeDataToSharedFolder(...);

      final int resolvedPort =
          int.tryParse(
            (await LocalDbDAO.instance.getHostPort() ?? "").trim(),
          ) ??
          5000;
      final String resolvedApiKey =
          (await LocalDbDAO.instance.getApiKey() ?? "").trim();
      final String resolvedShopfrontId =
          (await LocalDbDAO.instance.getShopfrontId() ?? "").trim();

      if (address.trim().isEmpty ||
          resolvedApiKey.isEmpty ||
          resolvedShopfrontId.isEmpty) {
        throw Exception("Missing host/shopfront setup for stocktake commit.");
      }

      final DateTime dateStarted = adjustedData.isNotEmpty
          ? adjustedData
                .map((e) => e.stocktakeDate)
                .reduce((a, b) => a.isBefore(b) ? a : b)
          : DateTime.now();
      final DateTime dateEnded = adjustedData.isNotEmpty
          ? adjustedData
                .map((e) => e.dateModified)
                .reduce((a, b) => a.isAfter(b) ? a : b)
          : DateTime.now();

      final body = <String, dynamic>{
        "mobile_device_id": mobileID,
        "mobile_device_name": mobileName,
        "date_started": dateStarted.toIso8601String(),
        "date_ended": dateEnded.toIso8601String(),
        "data": adjustedData
            .map(
              (s) => {
                "stocktake_date": s.stocktakeDate.toIso8601String(),
                "stock_id": s.stockID,
                "quantity": s.quantity,
              },
            )
            .toList(),
      };

      await _enforceStocktakeApiCooldown();
      return DataAgentImpl.instance.stocktakeCommit(
        address,
        resolvedPort,
        resolvedShopfrontId,
        resolvedApiKey,
        body,
      );
    } on Exception catch (error) {
      return Future.error(error);
    }
  }

  @override
  Future stocktakeAndSaveToLocalDb(
    CountedStockVO stock,
    String shopfront,
  ) async {
    try {
      final Map<String, dynamic> data = {
        'stock_id': stock.stockID,
        'shopfront': shopfront,
        'quantity': stock.quantity,
        'inStock': stock.inStock,
        'stocktake_date': stock.stocktakeDate.toIso8601String(),
        'date_modified': stock.dateModified.toIso8601String(),
        'is_synced': stock.isSynced ? 1 : 0,
        'description': stock.description,
        'barcode': stock.barcode,
      };

      await LocalDbDAO.instance.saveCountedStock(data);
    } on Exception catch (error) {
      return Future.error(error);
    }
  }

  @override
  Future<List<CountedStockVO>> getAllStocktakeList(String shopfront) async {
    try {
      final List<Map<String, dynamic>> rawData = await LocalDbDAO.instance
          .getStocktakeList(shopfront: shopfront);
      return rawData.map((map) {
        return CountedStockVO(
          stockID: map['stock_id'],
          quantity: map['quantity'],
          stocktakeDate: DateTime.parse(map['stocktake_date']),
          dateModified: DateTime.parse(map['date_modified']),
          isSynced: map['is_synced'] == 1,
          description: map['description'],
          barcode: map['barcode'],
          inStock: map['inStock'],
        );
      }).toList();
    } on Exception catch (error) {
      return Future.error(error);
    }
  }

  @override
  Stream<AuditSyncStatus> fetchStocktakeAuditReport({
    required String ipAddress,
    required String fullPath,
    required String? username,
    required String? password,
    required String mobileID,
    required String shopfront,
  }) async* {
    // Old setup disabled:
    // pollForStocktakeValidationFile -> downloadAndDeleteFile -> gzip decode -> AuditReport.fromJson
    yield AuditSyncStatus(0, 1, "Processing validation result...");

    final report = _lastInitcheckResponse;
    if (report == null) {
      throw Exception(
        "No init-check result found. Please send validation first.",
      );
    }

    if (report.data.isEmpty) {
      yield AuditSyncStatus(1, 1, "No transactions found.", rows: const []);
      return;
    }

    yield AuditSyncStatus(0, 1, "Loading stock details...");

    final stockIds = report.data.map((e) => e.stockId).toList();

    final stockMap = await LocalDbDAO.instance.getStocksByIds(
      shopfront: shopfront,
      stockIds: stockIds,
    );

    final rows = report.data
        .map((a) => AuditWithStockVO(audit: a, stock: stockMap[a.stockId]))
        .toList();

    yield AuditSyncStatus(1, 1, "Transactions found.", rows: rows);
  }

  @override
  Future<void> updateStocktakeCount(
    StockVO stock,
    String shopfront,
    String newQty,
  ) async {
    try {
      num parsedQty;
      if (stock.allowFractions == true) {
        parsedQty = double.tryParse(newQty) ?? 0.0;
      } else {
        double inputAsDouble = double.tryParse(newQty) ?? 0.0;
        parsedQty = inputAsDouble.round();
      }

      await LocalDbDAO.instance.updateStockQuantity(
        stockId: stock.stockID.toInt(),
        shopfront: shopfront,
        newQuantity: parsedQty,
      );
    } on Exception catch (error) {
      return Future.error(error);
    }
  }

  @override
  Future<StocktakeLimitResponse> fetchStocktakeLimit({
    required String address,
  }) async {
    try {
      final int resolvedPort =
          int.tryParse(
            (await LocalDbDAO.instance.getHostPort() ?? "").trim(),
          ) ??
          5000;
      final String resolvedApiKey =
          (await LocalDbDAO.instance.getApiKey() ?? "").trim();

      if (address.trim().isEmpty || resolvedApiKey.isEmpty) {
        throw Exception("Missing host/api-key setup for stocktake limit.");
      }

      return DataAgentImpl.instance.getStocktakeLimit(
        address,
        resolvedPort,
        resolvedApiKey,
      );
    } on Exception catch (error) {
      return Future.error(error);
    }
  }

  @override
  Future<StocktakePagedResult> fetchUnsyncedStocktakePage({
    required String shopfront,
    required int pageIndex,
    required int pageSize,
    String? query,
  }) async {
    final offset = pageIndex * pageSize;

    final total = await LocalDbDAO.instance.getUnsyncedStocksCount(
      shopfront: shopfront,
      query: query,
    );

    final items = await LocalDbDAO.instance.getUnsyncedStocksPaged(
      shopfront: shopfront,
      limit: pageSize,
      offset: offset,
      query: query,
    );

    return StocktakePagedResult(items: items, totalCount: total);
  }

  @override
  Future backupToLanFodler({
    required String address,
    required String fullPath,
    required String? username,
    required String? password,
    required String mobileName,
    required String mobileID,
    required String shopfrontName,
    required List<CountedStockVO> dataToSync,
  }) async {
    try {
      // Old setup disabled:
      // final String jsonContent = _StocktakeJsonBuilder.buildJson(...);
      // final String fileName = "${mobileID}_backup_${shopfrontInFileName}_$timestamp.json.gz";
      // return LanNetworkServiceImpl.instance.writeStocktakeDataToSharedFolder(...);

      final int resolvedPort =
          int.tryParse(
            (await LocalDbDAO.instance.getHostPort() ?? "").trim(),
          ) ??
          5000;
      final String resolvedApiKey =
          (await LocalDbDAO.instance.getApiKey() ?? "").trim();
      final String resolvedShopfrontId =
          (await LocalDbDAO.instance.getShopfrontId() ?? "").trim();

      if (address.trim().isEmpty ||
          resolvedApiKey.isEmpty ||
          resolvedShopfrontId.isEmpty) {
        throw Exception("Missing host/shopfront setup for backup.");
      }

      final List<CountedStockVO> sortedStocks = List<CountedStockVO>.from(
        dataToSync,
      )..sort((a, b) => a.stocktakeDate.compareTo(b.stocktakeDate));

      final DateTime dateStarted = sortedStocks.isNotEmpty
          ? sortedStocks.first.stocktakeDate
          : DateTime.now();
      final DateTime dateEnded = sortedStocks.isNotEmpty
          ? sortedStocks.last.dateModified
          : DateTime.now();

      final body = <String, dynamic>{
        "mobile_device_id": mobileID,
        "mobile_device_name": mobileName,
        "shopfront": shopfrontName,
        "total_stocks": dataToSync.length,
        "date_started": dateStarted.toIso8601String(),
        "date_ended": dateEnded.toIso8601String(),
        "data": dataToSync
            .map(
              (s) => {
                "stocktake_date": s.stocktakeDate.toIso8601String(),
                "stock_id": s.stockID,
                "quantity": s.quantity,
                "date_modified": s.dateModified.toIso8601String(),
              },
            )
            .toList(),
      };

      final response = await DataAgentImpl.instance.stocktakeBackup(
        address,
        resolvedPort,
        resolvedShopfrontId,
        resolvedApiKey,
        body,
      );
      if (!response.success) {
        throw Exception(response.message);
      }
      return;
    } on Exception catch (error) {
      return Future.error(error);
    }
  }

  @override
  Future<List<BackupStocktakeItemVO>> fetchBackupItems({
    required String address,
    required String fullPath,
    required String username,
    required String password,
    required String fileName,
  }) async {
    // Old setup disabled:
    // final Uint8List gzBytes = await LanNetworkServiceImpl.instance.downloadBackupFileBytes(...);
    // final jsonString = utf8.decode(GZipCodec().decode(gzBytes));
    // final Map<String, dynamic> decoded = jsonDecode(jsonString);

    final int resolvedPort =
        int.tryParse((await LocalDbDAO.instance.getHostPort() ?? "").trim()) ??
        5000;
    final String resolvedApiKey = (await LocalDbDAO.instance.getApiKey() ?? "")
        .trim();
    final String resolvedShopfrontId =
        (await LocalDbDAO.instance.getShopfrontId() ?? "").trim();

    if (address.trim().isEmpty ||
        resolvedApiKey.isEmpty ||
        resolvedShopfrontId.isEmpty) {
      throw Exception("Missing host/shopfront setup for loading backup.");
    }

    final response = await DataAgentImpl.instance.loadStocktakeBackup(
      address,
      resolvedPort,
      resolvedShopfrontId,
      fileName,
      resolvedApiKey,
    );
    if (!response.success) {
      throw Exception(response.message);
    }

    return response.data.data;
  }

  @override
  Future<List<BackupSessionVO>> fetchBackupSessions({
    required String address,
    required String fullPath,
    required String username,
    required String password,
    required String mobileId,
  }) async {
    // Old setup disabled:
    // final names = await LanNetworkServiceImpl.instance.listBackupFiles(...);

    final int resolvedPort =
        int.tryParse((await LocalDbDAO.instance.getHostPort() ?? "").trim()) ??
        5000;
    final String resolvedApiKey = (await LocalDbDAO.instance.getApiKey() ?? "")
        .trim();
    final String resolvedShopfrontId =
        (await LocalDbDAO.instance.getShopfrontId() ?? "").trim();

    if (address.trim().isEmpty ||
        resolvedApiKey.isEmpty ||
        resolvedShopfrontId.isEmpty) {
      throw Exception("Missing host/shopfront setup for backup sessions.");
    }

    final response = await DataAgentImpl.instance.getStocktakeBackupList(
      address,
      resolvedPort,
      resolvedShopfrontId,
      resolvedApiKey,
    );
    if (!response.success) {
      throw Exception(response.message);
    }

    return response.items.map((item) {
      final parsed = DateTime.tryParse(item.lastWriteUtc);
      final dt = parsed != null ? parsed.toLocal() : DateTime.now();
      return BackupSessionVO(fileName: item.fileName, createdAt: dt);
    }).toList();
  }

  // Old setup disabled:
  // DateTime? _parseTimestampFromFileName(String fileName) { ... }
}

class StocktakePagedResult {
  final List<CountedStockVO> items;
  final int totalCount;

  StocktakePagedResult({required this.items, required this.totalCount});
}

class AuditWithStockVO {
  final AuditItem audit;
  final StockVO? stock;

  AuditWithStockVO({required this.audit, required this.stock});
}

class AuditSyncStatus {
  final int processed;
  final int total;
  final String message;

  final List<AuditWithStockVO>? rows;

  AuditSyncStatus(this.processed, this.total, this.message, {this.rows});
}

// Old setup disabled:
// class _StocktakeJsonBuilder {
//   static String buildJson(...) { ... }
// }

class TransactionTypeHelper {
  static String translate(String code) {
    switch (code) {
      case "IV":
        return "Invoice";
      case "SA":
        return "Sale";
      case "LB":
        return "Lay-by";
      case "SO":
        return "Sales Order";
      case "QU":
        return "Quote";
      case "CS":
        return "Special Order";
      case "GR":
        return "Goods Received";
      case "RG":
        return "Returned Goods";
      case "PO":
        return "Purchase Order";
      case "ST":
        return "Stocktake";
      case "SL":
        return "Partial Stocktake";
      case "SI":
        return "Single Stocktake";
      case "MR":
        return "Merge";
      case "VC":
        return "Cost Change";
      case "VS":
        return "Sell Price Change";
      case "IP":
        return "Invoice Payment";
      case "LP":
        return "Lay-by Payment";
      case "SP":
        return "Sales Order Payment";
      case "LC":
        return "Lay-by Conversion";
      case "SC":
        return "Sales Order Conversion";

      default:
        return code;
    }
  }

  static IconData getIcon(String code) {
    if (["SA", "IV", "LB"].contains(code)) return Icons.shopping_cart_outlined;
    if (["GR", "PO"].contains(code)) return Icons.inventory_2_outlined;
    if (["RG"].contains(code)) return Icons.assignment_return_outlined;
    if (["ST", "SL", "SI"].contains(code)) return Icons.fact_check_outlined;
    return Icons.receipt_long_outlined;
  }
}
