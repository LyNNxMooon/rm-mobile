import '../repositories/customer_lookup_repo.dart';

class GetShopfrontName {
  final CustomerLookupRepo repository;

  GetShopfrontName(this.repository);

  Future<String> call() async {
    try {
      return (await repository.getShopfrontName()) ?? '';
    } catch (error) {
      return Future.error(error);
    }
  }
}
