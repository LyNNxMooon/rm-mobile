import 'package:rmstock_scanner/entities/response/customer_create_response.dart';

import '../repositories/customer_lookup_repo.dart';

class CreateCustomer {
  final CustomerLookupRepo repository;

  CreateCustomer(this.repository);

  Future<CustomerCreateResponse> call(Map<String, dynamic> body) async {
    try {
      return await repository.createCustomer(body);
    } catch (e) {
      return Future.error("Failed to create customer: $e");
    }
  }
}
