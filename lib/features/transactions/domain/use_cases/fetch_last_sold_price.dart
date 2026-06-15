import '../../../../entities/vos/stock_vo.dart';
import '../../../../utils/global_var_utils.dart';
import '../repositories/sales_repo.dart';

/// Use case for fetching and storing the last sold price of a stock item.
class FetchLastSoldPrice {
  final SalesRepo repository;

  FetchLastSoldPrice(this.repository);

  /// Fetches the last sold price for the given stock from the server,
  /// stores it locally, and returns it (null if never sold).
  Future<double?> call(StockVO stock) {
    final String shopfront = AppGlobals.instance.shopfront ?? "";
    return repository.fetchAndStoreLastSoldPrice(stock.stockID.toInt(), shopfront);
  }
}
