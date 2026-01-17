import 'dart:convert';

import 'package:rmstock_scanner/entities/vos/counted_stock_vo.dart';
import '../../../entities/vos/stock_vo.dart';
import '../../../local_db/local_db_dao.dart';
import '../../../network/LAN_sharing/lan_network_service_impl.dart';
import '../domain/repositories/stocktake_repo.dart';

class StocktakeModel implements StocktakeRepo {
  //Data manipulation can be done here (E.g. substituting data for null values returned from API)

  @override
  Future<StockVO> fetchStockDetails(String barcode) async {
    throw UnimplementedError();
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

      String _pad(int value) => value.toString().padLeft(2, '0');

      final String timestamp =
          "${now.year}"
          "${_pad(now.month)}"
          "${_pad(now.day)}"
          "${_pad(now.hour)}"
          "${_pad(now.minute)}"
          "${_pad(now.second)}";

      final String fileName = "${mobileName}_initCheck_$timestamp.json";

      return LanNetworkServiceImpl.instance.writeStocktakeDataToSharedFolder(
        address: address,
        fullPath: fullPath,
        username: username ?? "Guest",
        password: password ?? "",
        fileName: fileName,
        fileContent: jsonContent,
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
