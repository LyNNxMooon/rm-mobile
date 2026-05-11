import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rmmobile/features/customer_lookup/domain/entities/customer_transactions_local_data.dart';
import 'package:rmmobile/features/customer_lookup/domain/use_cases/fetch_customer_transactions.dart';
import 'package:rmmobile/features/customer_lookup/domain/use_cases/fetch_customer_transactions_by_type.dart';
import 'package:rmmobile/features/customer_lookup/domain/use_cases/get_customer_transactions_local.dart';
import 'package:rmmobile/features/customer_lookup/presentation/BLoC/customer_transactions_events.dart';
import 'package:rmmobile/features/customer_lookup/presentation/BLoC/customer_transactions_states.dart';
import 'package:rmmobile/utils/internet_connection_utils.dart';

class CustomerTransactionsBloc
    extends Bloc<CustomerTransactionsEvent, CustomerTransactionsState> {
  final GetCustomerTransactionsLocal getCustomerTransactionsLocal;
  final FetchCustomerTransactions fetchCustomerTransactions;
  final FetchCustomerTransactionsByType fetchCustomerTransactionsByType;

  int _currentPageSize = 500;
  
  // Store pagination cursors per transaction type
  final Map<String, int?> _cursors = {};

  CustomerTransactionsBloc({
    required this.getCustomerTransactionsLocal,
    required this.fetchCustomerTransactions,
    required this.fetchCustomerTransactionsByType,
  }) : super(CustomerTransactionsInitial()) {
    on<LoadCustomerTransactionsEvent>(_onLoadCustomerTransactions);
    on<LoadTransactionTypeEvent>(_onLoadTransactionType);
    on<LoadNextPageEvent>(_onLoadNextPage);
    on<UpdatePageSizeEvent>(_onUpdatePageSize);
  }

  int get currentPageSize => _currentPageSize;

  Future<void> syncCustomerTransactions(int customerId) async {
    await fetchCustomerTransactions(customerId);
  }

  Future<void> _onLoadCustomerTransactions(
    LoadCustomerTransactionsEvent event,
    Emitter<CustomerTransactionsState> emit,
  ) async {
    emit(CustomerTransactionsLoading());
    try {
      // Clear cursors on fresh load
      _cursors.clear();
      
      // Check connectivity and fetch from API if online
      final isOnline = await InternetConnectionUtils.instance.checkInternetConnection();
      CustomerTransactionsLocalData data;
      
      if (isOnline) {
        // Fetch purchases (default first tab) with default page size
        final result = await fetchCustomerTransactionsByType(
          event.customerId,
          transactionType: 'purchase',
          pageSize: _currentPageSize,
        );
        
        // Load all data from local DB
        data = await getCustomerTransactionsLocal(event.customerId);
        
        // Update pagination info
        data = data.copyWithPagination(
          'purchase',
          TransactionPaginationInfo(
            hasMore: result.hasMore,
            nextCursor: result.nextCursor,
          ),
        );
        _cursors['purchase'] = result.nextCursor;
      } else {
        data = await getCustomerTransactionsLocal(event.customerId);
      }

      emit(CustomerTransactionsLoaded(data, pageSize: _currentPageSize));
    } catch (error) {
      // If API call fails but we have local data, still show it
      try {
        final data = await getCustomerTransactionsLocal(event.customerId);
        if (_hasAnyData(data)) {
          emit(CustomerTransactionsLoaded(data, pageSize: _currentPageSize));
        } else {
          emit(CustomerTransactionsError(error.toString()));
        }
      } catch (_) {
        emit(CustomerTransactionsError(error.toString()));
      }
    }
  }

  Future<void> _onLoadTransactionType(
    LoadTransactionTypeEvent event,
    Emitter<CustomerTransactionsState> emit,
  ) async {
    // Get current data to show loading state with existing data
    CustomerTransactionsLocalData? currentData;
    if (state is CustomerTransactionsLoaded) {
      currentData = (state as CustomerTransactionsLoaded).data;
      emit(TransactionTypeLoading(currentData, event.transactionType));
    } else if (state is TransactionTypeLoading) {
      currentData = (state as TransactionTypeLoading).data;
      emit(TransactionTypeLoading(currentData, event.transactionType));
    } else {
      emit(CustomerTransactionsLoading());
    }

    try {
      // Check connectivity and fetch from API if online
      final isOnline = await InternetConnectionUtils.instance.checkInternetConnection();
      CustomerTransactionsLocalData data;
      
      if (isOnline) {
        final result = await fetchCustomerTransactionsByType(
          event.customerId,
          transactionType: event.transactionType,
          pageSize: event.pageSize,
          cursor: event.cursor,
        );

        // Load all data from local DB
        data = await getCustomerTransactionsLocal(event.customerId);
        
        // Update pagination info
        data = data.copyWithPagination(
          event.transactionType,
          TransactionPaginationInfo(
            hasMore: result.hasMore,
            nextCursor: result.nextCursor,
          ),
        );
        _cursors[event.transactionType] = result.nextCursor;
      } else {
        data = await getCustomerTransactionsLocal(event.customerId);
        // Preserve existing pagination info
        if (currentData != null) {
          final existingPagination = currentData.pagination;
          for (final entry in existingPagination.entries) {
            data = data.copyWithPagination(entry.key, entry.value);
          }
        }
      }

      emit(CustomerTransactionsLoaded(data, pageSize: _currentPageSize));
    } catch (error) {
      // If API call fails but we have local data, still show it
      if (currentData != null) {
        emit(CustomerTransactionsLoaded(currentData, pageSize: _currentPageSize));
      } else {
        try {
          final data = await getCustomerTransactionsLocal(event.customerId);
          emit(CustomerTransactionsLoaded(data, pageSize: _currentPageSize));
        } catch (_) {
          emit(CustomerTransactionsError(error.toString()));
        }
      }
    }
  }

  Future<void> _onLoadNextPage(
    LoadNextPageEvent event,
    Emitter<CustomerTransactionsState> emit,
  ) async {
    // Get current data to show loading state with existing data
    CustomerTransactionsLocalData? currentData;
    if (state is CustomerTransactionsLoaded) {
      currentData = (state as CustomerTransactionsLoaded).data;
      emit(TransactionTypeLoading(currentData, event.transactionType));
    } else {
      return; // Can't load next page without current data
    }

    try {
      final result = await fetchCustomerTransactionsByType(
        event.customerId,
        transactionType: event.transactionType,
        pageSize: event.pageSize,
        cursor: event.cursor,
      );

      // Load all data from local DB (will include appended records)
      var data = await getCustomerTransactionsLocal(event.customerId);
      
      // Preserve existing pagination info and update this type
      for (final entry in currentData.pagination.entries) {
        if (entry.key != event.transactionType) {
          data = data.copyWithPagination(entry.key, entry.value);
        }
      }
      
      // Update pagination info for this type
      data = data.copyWithPagination(
        event.transactionType,
        TransactionPaginationInfo(
          hasMore: result.hasMore,
          nextCursor: result.nextCursor,
        ),
      );
      _cursors[event.transactionType] = result.nextCursor;

      emit(CustomerTransactionsLoaded(data, pageSize: _currentPageSize));
    } catch (error) {
      // On error, show current data
      emit(CustomerTransactionsLoaded(currentData, pageSize: _currentPageSize));
    }
  }

  Future<void> _onUpdatePageSize(
    UpdatePageSizeEvent event,
    Emitter<CustomerTransactionsState> emit,
  ) async {
    _currentPageSize = event.pageSize;
    
    // Clear cursors when page size changes (fresh fetch)
    _cursors.clear();

    // Get current data to show loading state
    CustomerTransactionsLocalData? currentData;
    if (state is CustomerTransactionsLoaded) {
      currentData = (state as CustomerTransactionsLoaded).data;
      emit(TransactionTypeLoading(currentData, event.transactionType));
    } else {
      emit(CustomerTransactionsLoading());
    }

    try {
      // Fetch with new page size
      final isOnline = await InternetConnectionUtils.instance.checkInternetConnection();
      CustomerTransactionsLocalData data;
      
      if (isOnline) {
        final result = await fetchCustomerTransactionsByType(
          event.customerId,
          transactionType: event.transactionType,
          pageSize: event.pageSize,
        );

        // Load all data from local DB
        data = await getCustomerTransactionsLocal(event.customerId);
        
        // Update pagination info
        data = data.copyWithPagination(
          event.transactionType,
          TransactionPaginationInfo(
            hasMore: result.hasMore,
            nextCursor: result.nextCursor,
          ),
        );
        _cursors[event.transactionType] = result.nextCursor;
      } else {
        data = await getCustomerTransactionsLocal(event.customerId);
      }

      emit(CustomerTransactionsLoaded(data, pageSize: _currentPageSize));
    } catch (error) {
      if (currentData != null) {
        emit(CustomerTransactionsLoaded(currentData, pageSize: _currentPageSize));
      } else {
        emit(CustomerTransactionsError(error.toString()));
      }
    }
  }

  bool _hasAnyData(CustomerTransactionsLocalData data) {
    return data.purchases.isNotEmpty ||
        data.credit.isNotEmpty ||
        data.invoices.isNotEmpty ||
        data.ivPay.isNotEmpty ||
        data.laybys.isNotEmpty ||
        data.lbPay.isNotEmpty ||
        data.cso.isNotEmpty ||
        data.soQuote.isNotEmpty ||
        data.soPay.isNotEmpty;
  }
}
