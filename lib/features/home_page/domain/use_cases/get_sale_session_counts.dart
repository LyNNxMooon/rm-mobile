import 'package:rmmobile/features/home_page/domain/repositories/home_repo.dart';

class GetSaleSessionCounts {
  final HomeRepo repo;

  GetSaleSessionCounts(this.repo);

  Future<Map<String, int>> call(String shopfront) {
    return repo.getSaleSessionCounts(shopfront);
  }
}
