import 'package:rmmobile/entities/vos/stock_vo.dart';
import 'package:rmmobile/features/stocktake/domain/repositories/stocktake_repo.dart';
import 'package:rmmobile/utils/global_var_utils.dart';

class UpdateStockCount {
  final StocktakeRepo repository;

  UpdateStockCount(this.repository);

  Future<void> call(StockVO stockId, String newQty) {
    try {
      final String shopfront = AppGlobals.instance.shopfront ?? "";

      return repository.updateStocktakeCount(stockId, shopfront, newQty);
    } catch (error) {
      return Future.error(error);
    }
  }
}
