import '../../../../entities/vos/stock_vo.dart';
import '../../../../utils/global_var_utils.dart';
import '../repositories/sales_repo.dart';

/// Use case for reading the locally stored (cached) last sold price of a stock.
class GetStoredLastSoldPrice {
  final SalesRepo repository;

  GetStoredLastSoldPrice(this.repository);

  /// Returns the cached last sold price for the given stock, or null if none stored.
  Future<double?> call(StockVO stock) {
    final String shopfront = AppGlobals.instance.shopfront ?? "";
    return repository.getStoredLastSoldPrice(stock.stockID.toInt(), shopfront);
  }
}
