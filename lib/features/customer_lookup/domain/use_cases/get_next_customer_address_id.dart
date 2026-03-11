import '../repositories/customer_lookup_repo.dart';

class GetNextCustomerAddressId {
  final CustomerLookupRepo repository;

  GetNextCustomerAddressId(this.repository);

  Future<int> call({required String shopfront}) async {
    try {
      return await repository.getNextCustomerAddressId(shopfront: shopfront);
    } catch (e) {
      return Future.error("Failed to get next customer address ID: $e");
    }
  }
}
