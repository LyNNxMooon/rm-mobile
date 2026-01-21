import 'package:rmstock_scanner/entities/vos/counted_stock_vo.dart';
import 'package:rmstock_scanner/entities/vos/stock_vo.dart';

abstract class StocktakeRepo {
  Future<StockVO?> fetchStockDetails(String barcode, String shopfront);

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

  Future<List<CountedStockVO>> getAllStocktakeList(String shopfront);
}
