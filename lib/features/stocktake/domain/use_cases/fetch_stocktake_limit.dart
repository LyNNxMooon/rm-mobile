import 'package:rmmobile/entities/response/stocktake_limit_response.dart';
import 'package:rmmobile/features/stocktake/domain/repositories/stocktake_repo.dart';
import 'package:rmmobile/utils/global_var_utils.dart';

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
