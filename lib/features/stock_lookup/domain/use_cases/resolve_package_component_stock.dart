import '../../../../entities/vos/stock_vo.dart';
import '../repositories/stock_lookup_repo.dart';

class ResolvePackageComponentStock {
  final StockLookupRepo repository;

  ResolvePackageComponentStock(this.repository);

  Future<StockVO?> call({required int stockId, String? barcode}) async {
    try {
      return await repository.resolvePackageComponentStock(
        stockId: stockId,
        barcode: barcode,
      );
    } catch (error) {
      return Future.error(error);
    }
  }
}
