import 'package:rmstock_scanner/features/stock_lookup/domain/repositories/stock_lookup_repo.dart';

class GetFilterOptions {
  final StockLookupRepo repository;

  GetFilterOptions(this.repository);

  Future<Map<String, List<String>>> call() async {
    try {
      // For now, we just pass through to the repository
      return await repository.getFilterOptions();
    } catch (error) {
      return Future.error(error);
    }
  }
}
