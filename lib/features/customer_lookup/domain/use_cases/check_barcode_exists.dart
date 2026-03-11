import '../repositories/customer_lookup_repo.dart';

class CheckBarcodeExists {
  final CustomerLookupRepo repository;

  CheckBarcodeExists(this.repository);

  Future<bool> call({required String shopfront, required String barcode}) async {
    try {
      return await repository.checkBarcodeExists(
        shopfront: shopfront,
        barcode: barcode,
      );
    } catch (e) {
      return Future.error("Failed to check barcode: $e");
    }
  }
}
