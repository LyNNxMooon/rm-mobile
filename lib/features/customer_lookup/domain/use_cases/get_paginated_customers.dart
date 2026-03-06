import '../../../../entities/response/paginated_customer_response.dart';
import '../../../../entities/vos/filter_criteria.dart';
import '../repositories/customer_lookup_repo.dart';

class GetPaginatedCustomers {
  final CustomerLookupRepo repository;

  GetPaginatedCustomers(this.repository);

  Future<PaginatedCustomerResult> call({
    required String shopfront,
    String query = "",
    String filterCol = "surname",
    String sortCol = "surname",
    bool ascending = true,
    required int page,
    FilterCriteria? filters,
  }) async {
    try {
      return repository.fetchCustomersDynamic(
        shopfront: shopfront,
        query: query,
        filterColumn: filterCol,
        sortColumn: sortCol,
        ascending: ascending,
        page: page,
        filters: filters
      );
    } catch (e) {
      return Future.error("Failed to load customers $page: $e");
    }
  }
}
