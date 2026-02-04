import 'package:rmstock_scanner/entities/response/stock_search_resposne.dart';
import 'package:rmstock_scanner/features/stocktake/domain/repositories/stocktake_repo.dart';

import '../../../../utils/global_var_utils.dart';

class FetchCountingStock {
  final StocktakeRepo repository;

  FetchCountingStock(this.repository);

  Future<StockSearchResult> call(String query) {
    final String shopfront = AppGlobals.instance.shopfront ?? "";
    return repository.fetchStockDetails(query, shopfront);
  }
}

