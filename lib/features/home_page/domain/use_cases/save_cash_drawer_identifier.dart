import '../repositories/home_repo.dart';

class SaveCashDrawerIdentifier {
  final HomeRepo repository;

  SaveCashDrawerIdentifier(this.repository);

  Future<void> call(String identifier) async {
    try {
      await repository.saveCashDrawerIdentifier(identifier);
    } catch (error) {
      return Future.error(error);
    }
  }
}
