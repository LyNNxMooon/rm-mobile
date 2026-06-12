import '../../../../entities/response/stock_activity_response.dart';
import '../repositories/stock_lookup_repo.dart';

class FetchStockActivity {
  final StockLookupRepo repository;

  FetchStockActivity(this.repository);

  Future<StockActivityResponse> call({required int stockId}) async {
    try {
      return await repository.fetchStockActivity(stockId: stockId);
    } catch (error) {
      return Future.error(error);
    }
  }
}
