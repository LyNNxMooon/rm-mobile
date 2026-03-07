import '../../../../entities/response/paginated_customer_response.dart';
import '../../../../entities/response/staff_detail_response.dart';
import '../../../../entities/vos/filter_criteria.dart';
import '../entities/customer_sync_status.dart';

abstract class CustomerLookupRepo {
  Stream<CustomerSyncStatus> fetchAndSaveCustomers(String ipAddress);

  Future<PaginatedCustomerResult> fetchCustomersDynamic({
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

  Future<StaffDetailResponse> fetchStaffDetail(int staffId);
}
