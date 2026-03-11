import '../repositories/customer_lookup_repo.dart';

class GetHostIpAddress {
  final CustomerLookupRepo repository;

  GetHostIpAddress(this.repository);

  Future<String?> call() async {
    try {
      return await repository.getHostIpAddress();
    } catch (e) {
      return Future.error("Failed to get host IP address: $e");
    }
  }
}
