import 'package:rmmobile/entities/response/customer_balance_response.dart';

import '../repositories/customer_lookup_repo.dart';

class FetchCustomerBalance {
  final CustomerLookupRepo repository;

  FetchCustomerBalance(this.repository);

  Future<CustomerBalanceResponse> call(int customerId) async {
    try {
      return await repository.fetchCustomerBalance(customerId: customerId);
    } catch (e) {
      return Future.error("Failed to load customer balance: $e");
    }
  }
}
