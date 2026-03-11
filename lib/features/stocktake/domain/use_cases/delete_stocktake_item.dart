import '../repositories/stocktake_repo.dart';

class DeleteStocktakeItem {
  final StocktakeRepo repository;

  DeleteStocktakeItem(this.repository);

  Future<void> call({required int stockId, required String shopfront}) async {
    try {
      await repository.deleteStocktakeItem(
        stockId: stockId,
        shopfront: shopfront,
      );
    } catch (e) {
      return Future.error("Failed to delete stocktake item: $e");
    }
  }
}
