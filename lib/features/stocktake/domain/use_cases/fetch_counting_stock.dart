import 'package:rmstock_scanner/entities/vos/stock_vo.dart';
import 'package:rmstock_scanner/features/stocktake/domain/repositories/stocktake_repo.dart';

import '../../../../utils/global_var_utils.dart';

class FetchCountingStock {
  final StocktakeRepo repository;

  FetchCountingStock(this.repository);

  Future<StockVO?> call(String barcode) {
    try {
      final String shopfront = AppGlobals.instance.shopfront ?? "";

      return repository.fetchStockDetails(barcode, shopfront);
    } catch (error) {
      return Future.error(error);
    }
  }
}
