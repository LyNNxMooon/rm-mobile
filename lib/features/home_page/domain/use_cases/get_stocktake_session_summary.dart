import 'package:rmmobile/features/home_page/domain/repositories/home_repo.dart';

class GetStocktakeSessionSummary {
  final HomeRepo repo;

  GetStocktakeSessionSummary(this.repo);

  Future<Map<String, dynamic>> call(String shopfront) {
    return repo.getStocktakeSessionSummary(shopfront);
  }
}
