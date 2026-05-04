import 'package:rmmobile/features/home_page/domain/repositories/home_repo.dart';

class GetSaleSessionSummaries {
  final HomeRepo repo;

  GetSaleSessionSummaries(this.repo);

  Future<Map<String, Map<String, dynamic>>> call(String shopfront) {
    return repo.getSaleSessionSummaries(shopfront);
  }
}
