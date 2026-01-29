import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:rmstock_scanner/entities/response/audit_report_response.dart';
import 'package:rmstock_scanner/entities/vos/audit_item_vo.dart';
import 'package:rmstock_scanner/entities/vos/counted_stock_vo.dart';
import 'package:rmstock_scanner/utils/global_var_utils.dart';
import '../../../entities/vos/stock_vo.dart';
import '../../../local_db/local_db_dao.dart';
import '../../../network/LAN_sharing/lan_network_service_impl.dart';
import '../domain/repositories/stocktake_repo.dart';

class StocktakeModel implements StocktakeRepo {
  //Data manipulation can be done here (E.g. substituting data for null values returned from API)

  @override
  Future<StockVO?> fetchStockDetails(String barcode, String shopfront) async {
    try {
      return LocalDbDAO.instance.getStockBySearch(barcode, shopfront);
    } on Exception catch (error) {
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
  Future commitToLanFolder({
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
      final String jsonContent = _StocktakeJsonBuilder.buildJson(
        dataToSync,
        mobileID,
        mobileName,
        shopfrontName,
      );

      final now = DateTime.now();

      String pad(int value) => value.toString().padLeft(2, '0');

      final String timestamp =
          "${now.year}"
          "${pad(now.month)}"
          "${pad(now.day)}"
          "${pad(now.hour)}"
          "${pad(now.minute)}"
          "${pad(now.second)}";

      final String fileName = "${mobileID}_initCheck_$timestamp.json.gz";

      return LanNetworkServiceImpl.instance.writeStocktakeDataToSharedFolder(
        address: address,
        fullPath: fullPath,
        username: username ?? AppGlobals.instance.defaultUserName,
        password: password ?? AppGlobals.instance.defaultPwd,
        fileName: fileName,
        fileContent: jsonContent,
        isCheck: true,
      );
    } on Exception catch (error) {
      return Future.error(error);
    }
  }

  @override
  Future finalSendingStocktaketoRM({
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
            );
          }
        }
      }

      final String jsonContent = _StocktakeJsonBuilder.buildJson(
        adjustedData,
        mobileID,
        mobileName,
        shopfrontName,
      );

      final now = DateTime.now();

      String pad(int value) => value.toString().padLeft(2, '0');

      final String timestamp =
          "${now.year}"
          "${pad(now.month)}"
          "${pad(now.day)}"
          "${pad(now.hour)}"
          "${pad(now.minute)}"
          "${pad(now.second)}";

      final String fileName = "${mobileID}_stocktake_$timestamp.json.gz";

      return LanNetworkServiceImpl.instance.writeStocktakeDataToSharedFolder(
        address: address,
        fullPath: fullPath,
        username: username ?? AppGlobals.instance.defaultUserName,
        password: password ?? AppGlobals.instance.defaultPwd,
        fileName: fileName,
        fileContent: jsonContent,
        isCheck: false,
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
    final sanitizedId = mobileID.replaceAll(" ", "_");

    // same idea as stock sync
    yield AuditSyncStatus(0, 1, "Waiting for agent...");

    final file = await LanNetworkServiceImpl.instance
        .pollForStocktakeValidationFile(
          address: ipAddress,
          fullPath: fullPath,
          username: username ?? AppGlobals.instance.defaultUserName,
          password: password ?? AppGlobals.instance.defaultPwd,
          fileNamePattern: "${sanitizedId}_auditReport_",
          maxRetries: 60,
        );

    if (file == null) {
      throw Exception("RM-Mobile Manager did not respond in time.");
    }

    yield AuditSyncStatus(0, 1, "Downloading report...");

    final bytes = await LanNetworkServiceImpl.instance.downloadAndDeleteFile(
      address: ipAddress,
      username: username ?? AppGlobals.instance.defaultUserName,
      password: password ?? AppGlobals.instance.defaultPwd,
      fileToDownload: file,
    );

    yield AuditSyncStatus(0, 1, "Decoding report...");

    final jsonString = utf8.decode(GZipCodec().decode(bytes));
    final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
    final report = AuditReport.fromJson(decoded);

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
        // If fractional is allowed, parse directly to double
        parsedQty = double.tryParse(newQty) ?? 0.0;
      } else {
        // If not allowed, parse input and round to nearest integer
        // We parse as double first in case the user typed a dot by accident
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

class _StocktakeJsonBuilder {
  static String buildJson(
    List<CountedStockVO> stocks,
    String mobileId,
    String mobileName,
    String shopfrontName,
  ) {
    if (stocks.isEmpty) return "{}";

    // Sort to find correct start/end dates
    final sortedStocks = List<CountedStockVO>.from(stocks)
      ..sort((a, b) => a.stocktakeDate.compareTo(b.stocktakeDate));

    final firstRecord = sortedStocks.first;
    final lastRecord = sortedStocks.last;

    // Filter only required fields as per requirements
    final List<Map<String, dynamic>> dataList = sortedStocks.map((s) {
      return {
        "stocktake_date": s.stocktakeDate.toIso8601String(),
        "stock_id": s.stockID,
        "quantity": s.quantity,
        "date_modified": s.dateModified.toIso8601String(),
      };
    }).toList();

    final Map<String, dynamic> finalMap = {
      "mobile_device_id": mobileId,
      "mobile_device_name": mobileName,
      "shopfront": shopfrontName,
      "total_stocks": stocks.length,
      "date_started": firstRecord.stocktakeDate.toIso8601String(),
      "date_ended": lastRecord.dateModified.toIso8601String(),
      "data": dataList,
    };

    return const JsonEncoder.withIndent('  ').convert(finalMap);
  }
}

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
