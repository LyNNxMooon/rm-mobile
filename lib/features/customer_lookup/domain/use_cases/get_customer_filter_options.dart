import '../repositories/customer_lookup_repo.dart';

class GetCustomerFilterOptions {
  final CustomerLookupRepo repository;

  GetCustomerFilterOptions(this.repository);

  Future<Map<String, List<String>>> call(String shopfront) async {
    try {
      return await repository.getFilterOptions(shopfront);
    } catch (e) {
      return Future.error("Failed to load filter options: $e");
    }
  }
}
