import 'package:rmstock_scanner/entities/response/customer_update_response.dart';

import '../repositories/customer_lookup_repo.dart';

class UpdateCustomerDetails {
  final CustomerLookupRepo repository;

  UpdateCustomerDetails(this.repository);

  Future<CustomerUpdateResponse> call(Map<String, dynamic> body) async {
    try {
      return await repository.updateCustomerDetails(body);
    } catch (e) {
      return Future.error("Failed to update customer: $e");
    }
  }
}
