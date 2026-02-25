import 'package:rmstock_scanner/entities/response/stocktake_limit_response.dart';
import 'package:rmstock_scanner/features/stocktake/domain/repositories/stocktake_repo.dart';
import 'package:rmstock_scanner/utils/global_var_utils.dart';

class FetchStocktakeLimit {
  final StocktakeRepo repository;

  FetchStocktakeLimit(this.repository);

  Future<StocktakeLimitResponse> call() async {
    try {
      final ip = AppGlobals.instance.currentHostIp ?? "";
      return await repository.fetchStocktakeLimit(address: ip);
    } catch (error) {
      return Future.error(error);
    }
  }
}
