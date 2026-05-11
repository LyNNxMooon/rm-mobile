import 'package:rmmobile/features/customer_lookup/domain/entities/customer_transactions_local_data.dart';

abstract class CustomerTransactionsState {}

class CustomerTransactionsInitial extends CustomerTransactionsState {}

class CustomerTransactionsLoading extends CustomerTransactionsState {}

/// Loading state for a specific transaction type (for tab switching)
class TransactionTypeLoading extends CustomerTransactionsState {
  final CustomerTransactionsLocalData data;
  final String loadingType;

  TransactionTypeLoading(this.data, this.loadingType);
}

class CustomerTransactionsLoaded extends CustomerTransactionsState {
  final CustomerTransactionsLocalData data;
  final int pageSize;

  CustomerTransactionsLoaded(this.data, {this.pageSize = 500});
}

class CustomerTransactionsError extends CustomerTransactionsState {
  final String message;

  CustomerTransactionsError(this.message);
}
