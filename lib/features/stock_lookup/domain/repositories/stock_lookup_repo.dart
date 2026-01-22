import '../../../../entities/response/paginated_stock_response.dart';
import '../../../../entities/vos/filter_criteria.dart';

abstract class StockLookupRepo {
  Future<PaginatedStockResult> fetchStocksDynamic({
    required String shopfront,
    required String query,
    required String filterColumn,
    required String sortColumn,
    required bool ascending,
    required int page,
    FilterCriteria? filters,
    int pageSize,
  });

  Future<Map<String, List<String>>> getFilterOptions(String shopfront);
}
