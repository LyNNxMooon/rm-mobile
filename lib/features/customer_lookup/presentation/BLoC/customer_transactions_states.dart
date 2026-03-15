import 'package:rmstock_scanner/features/customer_lookup/domain/entities/customer_transactions_local_data.dart';

abstract class CustomerTransactionsState {}

class CustomerTransactionsInitial extends CustomerTransactionsState {}

class CustomerTransactionsLoading extends CustomerTransactionsState {}

class CustomerTransactionsLoaded extends CustomerTransactionsState {
  final CustomerTransactionsLocalData data;

  CustomerTransactionsLoaded(this.data);
}

class CustomerTransactionsError extends CustomerTransactionsState {
  final String message;

  CustomerTransactionsError(this.message);
}
