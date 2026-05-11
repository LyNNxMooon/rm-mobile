abstract class CustomerTransactionsEvent {}

class LoadCustomerTransactionsEvent extends CustomerTransactionsEvent {
  final int customerId;

  LoadCustomerTransactionsEvent({required this.customerId});
}

/// Event to load a specific transaction type when user switches tabs
class LoadTransactionTypeEvent extends CustomerTransactionsEvent {
  final int customerId;
  final String transactionType;
  final int pageSize;
  final int? cursor;

  LoadTransactionTypeEvent({
    required this.customerId,
    required this.transactionType,
    this.pageSize = 500,
    this.cursor,
  });
}

/// Event to load the next page of transactions
class LoadNextPageEvent extends CustomerTransactionsEvent {
  final int customerId;
  final String transactionType;
  final int pageSize;
  final int cursor;

  LoadNextPageEvent({
    required this.customerId,
    required this.transactionType,
    required this.pageSize,
    required this.cursor,
  });
}

/// Event to update the page size and refresh current tab
class UpdatePageSizeEvent extends CustomerTransactionsEvent {
  final int customerId;
  final String transactionType;
  final int pageSize;

  UpdatePageSizeEvent({
    required this.customerId,
    required this.transactionType,
    required this.pageSize,
  });
}
