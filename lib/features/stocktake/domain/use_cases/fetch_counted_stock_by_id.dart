import 'package:rmmobile/entities/vos/stock_vo.dart';
import 'package:rmmobile/features/stocktake/domain/repositories/stocktake_repo.dart';
import 'package:rmmobile/utils/global_var_utils.dart';

class FetchCountedStockById {
  final StocktakeRepo repository;

  FetchCountedStockById(this.repository);

  Future<StockVO?> call(int stockId) {
    try {
      final String shopfront = AppGlobals.instance.shopfront ?? "";

      return repository.fetchStockDetailsByID(stockId, shopfront);
    } catch (error) {
      return Future.error(error);
    }
  }
}
