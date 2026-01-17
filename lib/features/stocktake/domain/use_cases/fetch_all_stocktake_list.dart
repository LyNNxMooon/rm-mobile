import 'package:rmstock_scanner/entities/vos/counted_stock_vo.dart';
import 'package:rmstock_scanner/features/stocktake/domain/repositories/stocktake_repo.dart';

import '../../../../utils/global_var_utils.dart';

class FetchAllStocktakeList {
  final StocktakeRepo repository;

  FetchAllStocktakeList(this.repository);

  Future<List<CountedStockVO>> call() async {
    try {
      return await repository.getAllStocktakeList(
        AppGlobals.instance.shopfront ?? "",
      );
    } catch (error) {
      return Future.error(error);
    }
  }
}
