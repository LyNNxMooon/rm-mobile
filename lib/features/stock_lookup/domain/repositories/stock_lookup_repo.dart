import '../../../../entities/response/paginated_stock_response.dart';

abstract class StockLookupRepo {
  Future<PaginatedStockResult> fetchStocksDynamic({
    required String shopfront,
    required String query,
    required String filterColumn,
    required String sortColumn,
    required bool ascending,
    required int page,
    int pageSize,
  });

  Future<Map<String, List<String>>> getFilterOptions();
}
