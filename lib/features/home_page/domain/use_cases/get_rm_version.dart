import '../repositories/home_repo.dart';

class GetRmVersion {
  final HomeRepo repository;

  GetRmVersion(this.repository);

  Future<String?> call() async {
    try {
      return await repository.getRmVersion();
    } catch (error) {
      return Future.error(error);
    }
  }
}
