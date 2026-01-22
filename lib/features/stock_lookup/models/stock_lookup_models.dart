import 'package:rmstock_scanner/entities/response/paginated_stock_response.dart';
import 'package:rmstock_scanner/features/stock_lookup/domain/repositories/stock_lookup_repo.dart';

import '../../../entities/vos/filter_criteria.dart';
import '../../../local_db/local_db_dao.dart';

class StockLookupModels implements StockLookupRepo {
  //Data manipulation can be done here (E.g. substituting data for null values returned from API)
  @override
  Future<PaginatedStockResult> fetchStocksDynamic({
    required String shopfront,
    required String query,
    required String filterColumn,
    required String sortColumn,
    required bool ascending,
    required int page,
    FilterCriteria? filters,
    int pageSize = 100,
  }) async {
    try {
      final int offset = (page - 1) * pageSize;
      return LocalDbDAO.instance.searchAndSortStocks(
        shopfront: shopfront,
        query: query,
        filterColumn: filterColumn,
        sortColumn: sortColumn,
        ascending: ascending,
        limit: pageSize,
        offset: offset,
        filters: filters,
      );
    } on Exception catch (error) {
      return Future.error(error);
    }
  }

  @override
  Future<Map<String, List<String>>> getFilterOptions(String shopfront) async {
    try {
      final results = await Future.wait([
        LocalDbDAO.instance.getDistinctValues('dept_name', shopfront),
        LocalDbDAO.instance.getDistinctValues('cat1',shopfront),
        LocalDbDAO.instance.getDistinctValues('cat2',shopfront),
        LocalDbDAO.instance.getDistinctValues('cat3',shopfront),
      ]);

      return {
        'Departments': results[0],
        'Cat1': results[1],
        'Cat2': results[2],
        'Cat3': results[3],
      };
    } on Exception catch (error) {
      return Future.error("Failed to load filters: $error");
    }
  }
}
