import 'package:rmstock_scanner/features/stocktake/domain/repositories/stocktake_repo.dart';
import 'package:rmstock_scanner/features/stocktake/models/stocktake_model.dart';
import 'package:rmstock_scanner/utils/global_var_utils.dart';

class FetchStocktakePage {
  final StocktakeRepo repository;

  FetchStocktakePage(this.repository);

  Future<StocktakePagedResult> call({
    required int pageIndex,
    required int pageSize,
  }) async {
    try {
      String shopfront = AppGlobals.instance.shopfront ?? "";

      return await repository.fetchUnsyncedStocktakePage(
        shopfront: shopfront,
        pageIndex: pageIndex,
        pageSize: pageSize,
      );
    } catch (e) {
      return Future.error(e);
    }
  }
}
