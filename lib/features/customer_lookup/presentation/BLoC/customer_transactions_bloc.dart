import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rmstock_scanner/features/customer_lookup/domain/use_cases/get_customer_transactions_local.dart';
import 'package:rmstock_scanner/features/customer_lookup/presentation/BLoC/customer_transactions_events.dart';
import 'package:rmstock_scanner/features/customer_lookup/presentation/BLoC/customer_transactions_states.dart';

class CustomerTransactionsBloc
    extends Bloc<CustomerTransactionsEvent, CustomerTransactionsState> {
  final GetCustomerTransactionsLocal getCustomerTransactionsLocal;

  CustomerTransactionsBloc({required this.getCustomerTransactionsLocal})
      : super(CustomerTransactionsInitial()) {
    on<LoadCustomerTransactionsEvent>(_onLoadCustomerTransactions);
  }

  Future<void> _onLoadCustomerTransactions(
    LoadCustomerTransactionsEvent event,
    Emitter<CustomerTransactionsState> emit,
  ) async {
    emit(CustomerTransactionsLoading());
    try {
      final data = await getCustomerTransactionsLocal(event.customerId);
      emit(CustomerTransactionsLoaded(data));
    } catch (error) {
      emit(CustomerTransactionsError(error.toString()));
    }
  }
}
