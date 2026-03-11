import '../repositories/stocktake_repo.dart';

class HasUnsyncedStocktakes {
  final StocktakeRepo repository;

  HasUnsyncedStocktakes(this.repository);

  Future<bool> call({required String shopfront}) async {
    try {
      return await repository.hasUnsyncedStocktakes(shopfront);
    } catch (e) {
      return Future.error("Failed to check unsynced stocktakes: $e");
    }
  }
}
