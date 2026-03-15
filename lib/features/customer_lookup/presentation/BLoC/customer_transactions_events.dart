abstract class CustomerTransactionsEvent {}

class LoadCustomerTransactionsEvent extends CustomerTransactionsEvent {
  final int customerId;

  LoadCustomerTransactionsEvent({required this.customerId});
}
