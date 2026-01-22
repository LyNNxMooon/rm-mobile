import 'package:rmstock_scanner/features/stock_lookup/domain/repositories/stock_lookup_repo.dart';
import 'package:rmstock_scanner/utils/global_var_utils.dart';

class GetFilterOptions {
  final StockLookupRepo repository;

  GetFilterOptions(this.repository);

  Future<Map<String, List<String>>> call() async {
    try {
      // For now, we just pass through to the repository
      String shopfront = AppGlobals.instance.shopfront ?? "";
      return await repository.getFilterOptions(shopfront);
    } catch (error) {
      return Future.error(error);
    }
  }
}
