import '../repositories/stock_lookup_repo.dart';

class GetShopfrontName {
  final StockLookupRepo repository;

  GetShopfrontName(this.repository);

  Future<String> call() async {
    try {
      return (await repository.getShopfrontName()) ?? '';
    } catch (error) {
      return Future.error(error);
    }
  }
}
