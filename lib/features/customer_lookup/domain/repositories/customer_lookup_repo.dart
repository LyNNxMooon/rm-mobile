import '../../../../entities/response/paginated_customer_response.dart';
import '../../../../entities/response/staff_detail_response.dart';
import '../../../../entities/response/customer_update_response.dart';
import '../../../../entities/response/customer_create_response.dart';
import '../../../../entities/vos/filter_criteria.dart';
import '../../../../entities/vos/search_mode.dart';
import '../entities/customer_sync_status.dart';
import '../entities/customer_transactions_local_data.dart';

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
    SearchMode searchMode,
  });

  Future<Map<String, List<String>>> getFilterOptions(String shopfront);

  Future<StaffDetailResponse> fetchStaffDetail(int staffId);

  Future<StaffDetailResponse> fetchStaffByBarcode(String staffBarcode);

  Future<CustomerUpdateResponse> updateCustomerDetails(
    Map<String, dynamic> body,
  );

  Future<CustomerCreateResponse> createCustomer(
    Map<String, dynamic> body,
  );

  Future<void> fetchAndSaveCustomerTransactions({required int customerId});

  Future<CustomerTransactionsLocalData> getCustomerTransactionsLocal({
    required int customerId,
  });

  Future<bool> checkBarcodeExists({
    required String shopfront,
    required String barcode,
  });

  Future<String> getNextNumericBarcode({required String shopfront});

  Future<int> getNextCustomerId({required String shopfront});

  Future<int> getNextCustomerAddressId({required String shopfront});

  Future<String?> getHostIpAddress();

  Future<String?> getShopfrontName();
}
