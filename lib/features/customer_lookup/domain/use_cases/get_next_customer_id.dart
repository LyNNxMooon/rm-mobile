import '../repositories/customer_lookup_repo.dart';

class GetNextCustomerId {
  final CustomerLookupRepo repository;

  GetNextCustomerId(this.repository);

  Future<int> call({required String shopfront}) async {
    try {
      return await repository.getNextCustomerId(shopfront: shopfront);
    } catch (e) {
      return Future.error("Failed to get next customer ID: $e");
    }
  }
}
