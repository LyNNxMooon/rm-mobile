import '../repositories/home_repo.dart';

class GetCashDrawerIdentifier {
  final HomeRepo repository;

  GetCashDrawerIdentifier(this.repository);

  Future<String?> call() async {
    try {
      return await repository.getCashDrawerIdentifier();
    } catch (error) {
      return Future.error(error);
    }
  }
}
