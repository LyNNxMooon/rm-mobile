import '../../../../entities/response/stock_search_resposne.dart';
import '../../../../utils/global_var_utils.dart';
import '../repositories/sales_repo.dart';

/// Use case for searching stock to add to sales cart
class SearchStockForSale {
  final SalesRepo repository;

  SearchStockForSale(this.repository);

  /// Searches for stock by query (barcode → description → custom1 → custom2)
  /// Returns StockSearchResult with found stock, duplicates, or notFound
  Future<StockSearchResult> call(String query) {
    final String shopfront = AppGlobals.instance.shopfront ?? "";
    return repository.searchStockForSale(query, shopfront);
  }
}
