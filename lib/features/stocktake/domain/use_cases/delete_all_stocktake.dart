import '../repositories/stocktake_repo.dart';

class DeleteAllStocktake {
  final StocktakeRepo repository;

  DeleteAllStocktake(this.repository);

  Future<void> call() async {
    try {
      await repository.deleteAllStocktake();
    } catch (e) {
      return Future.error("Failed to delete all stocktake data: $e");
    }
  }
}
