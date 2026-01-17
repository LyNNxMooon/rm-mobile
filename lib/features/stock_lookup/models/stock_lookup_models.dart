import 'package:rmstock_scanner/entities/response/paginated_stock_response.dart';
import 'package:rmstock_scanner/features/stock_lookup/domain/repositories/stock_lookup_repo.dart';

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
      );
    } on Exception catch (error) {
      return Future.error(error);
    }
  }

  @override
  Future<Map<String, List<String>>> getFilterOptions() async {
    try {
      final results = await Future.wait([
        LocalDbDAO.instance.getDistinctValues('dept_name'),
        LocalDbDAO.instance.getDistinctValues('cat1'),
        LocalDbDAO.instance.getDistinctValues('cat2'),
        LocalDbDAO.instance.getDistinctValues('cat3'),
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
