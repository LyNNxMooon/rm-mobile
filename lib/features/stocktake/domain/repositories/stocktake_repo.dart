import 'package:rmstock_scanner/entities/vos/counted_stock_vo.dart';
import 'package:rmstock_scanner/entities/vos/stock_vo.dart';
import 'package:rmstock_scanner/features/stocktake/models/stocktake_model.dart';

abstract class StocktakeRepo {
  Future<StockVO?> fetchStockDetails(String barcode, String shopfront);
  Future<StockVO?> fetchStockDetailsByID(int id, String shopfront);

  Future stocktakeAndSaveToLocalDb(CountedStockVO stock, String shopfront);

  Future commitToLanFolder({
    required String address,
    required String fullPath,
    required String? username,
    required String? password,
    required String mobileName,
    required String mobileID,
    required String shopfrontName,
    required List<CountedStockVO> dataToSync,
  });

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
  });

  Future<List<CountedStockVO>> getAllStocktakeList(String shopfront);

  Stream<AuditSyncStatus> fetchStocktakeAuditReport({
    required String ipAddress,
    required String fullPath,
    required String? username,
    required String? password,
    required String mobileID,
    required String shopfront,
  });
}
