import '../entities/customer_transactions_local_data.dart';
import '../repositories/customer_lookup_repo.dart';

class GetCustomerTransactionsLocal {
  final CustomerLookupRepo repository;

  GetCustomerTransactionsLocal(this.repository);

  Future<CustomerTransactionsLocalData> call(int customerId) {
    return repository.getCustomerTransactionsLocal(customerId: customerId);
  }
}
