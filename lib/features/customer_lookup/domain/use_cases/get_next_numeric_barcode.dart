import '../repositories/customer_lookup_repo.dart';

class GetNextNumericBarcode {
  final CustomerLookupRepo repository;

  GetNextNumericBarcode(this.repository);

  Future<String> call({required String shopfront}) async {
    try {
      return await repository.getNextNumericBarcode(shopfront: shopfront);
    } catch (e) {
      return Future.error("Failed to generate barcode: $e");
    }
  }
}
