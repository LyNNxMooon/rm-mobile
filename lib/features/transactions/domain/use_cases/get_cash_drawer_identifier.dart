import '../repositories/sales_repo.dart';

class GetCashDrawerIdentifier {
  final SalesRepo repository;

  GetCashDrawerIdentifier(this.repository);

  Future<String> call({String fallback = 'M'}) async {
    try {
      final value = await repository.getCashDrawerIdentifier();
      if (value == null || value.trim().isEmpty) return fallback;
      return value.trim();
    } catch (error) {
      return Future.error(error);
    }
  }
}
