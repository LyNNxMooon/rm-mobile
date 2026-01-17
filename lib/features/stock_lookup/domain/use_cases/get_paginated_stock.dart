import '../../../../entities/response/paginated_stock_response.dart';
import '../repositories/stock_lookup_repo.dart';

class GetPaginatedStock {
  final StockLookupRepo repository;

  GetPaginatedStock(this.repository);

  Future<PaginatedStockResult> call({
    required String shopfront,
    String query = "",
    String filterCol = "description",
    String sortCol = "description",
    bool ascending = true,
    required int page,
  }) async {
    try {
      return repository.fetchStocksDynamic(
        shopfront: shopfront,
        query: query,
        filterColumn: filterCol,
        sortColumn: sortCol,
        ascending: ascending,
        page: page,
      );
    } catch (e) {
      return Future.error("Failed to load stocks $page: $e");
    }
  }
}
