import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rmstock_scanner/features/customer_lookup/domain/entities/customer_sync_status.dart';
import 'package:rmstock_scanner/features/customer_lookup/domain/use_cases/fetch_customer_data.dart';
import 'package:rmstock_scanner/features/customer_lookup/domain/use_cases/get_customer_filter_options.dart';
import 'package:rmstock_scanner/features/customer_lookup/domain/use_cases/get_paginated_customers.dart';
import 'package:rmstock_scanner/features/customer_lookup/presentation/BLoC/customer_lookup_events.dart';
import 'package:rmstock_scanner/features/customer_lookup/presentation/BLoC/customer_lookup_states.dart';

import '../../../../utils/global_var_utils.dart';

class CustomerListBloc extends Bloc<CustomerListEvent, CustomerListState> {
  final GetPaginatedCustomers getPaginatedCustomers;

  CustomerListBloc({required this.getPaginatedCustomers}) : super(CustomerListInitial()) {
    on<FetchFirstCustomerPageEvent>((event, emit) async {
      final prevState = state is CustomerListLoaded
          ? state as CustomerListLoaded
          : null;

      bool isAscending = prevState?.isAscending ?? true;

      if (event.shouldToggleSort &&
          prevState != null &&
          prevState.currentSortCol == event.sortColumn) {
        isAscending = !prevState.isAscending;
      }

      final criteria = event.filters ?? prevState?.activeFilters;

      emit(CustomerListLoading());

      try {
        final result = await getPaginatedCustomers.call(
          shopfront: AppGlobals.instance.shopfront ?? "",
          query: event.query,
          filterCol: event.filterColumn,
          sortCol: event.sortColumn,
          ascending: isAscending,
          page: 1,
          filters: criteria,
        );

        emit(
          CustomerListLoaded(
            customers: result.customers,
            totalCount: result.totalCount,
            hasReachedMax: result.customers.length < 100,
            currentPage: 1,
            currentQuery: event.query,
            currentSortCol: event.sortColumn,
            currentFilterCol: event.filterColumn,
            isAscending: isAscending,
            activeFilters: criteria,
          ),
        );
      } catch (e) {
        emit(CustomerListError(e.toString()));
      }
    });

    on<LoadMoreCustomersEvent>((event, emit) async {
      if (state is CustomerListLoaded) {
        final curr = state as CustomerListLoaded;
        if (curr.hasReachedMax) return;

        try {
          final nextPage = curr.currentPage + 1;
          final result = await getPaginatedCustomers.call(
            shopfront: AppGlobals.instance.shopfront ?? "",
            query: curr.currentQuery,
            filterCol: curr.currentFilterCol,
            sortCol: curr.currentSortCol,
            ascending: curr.isAscending,
            page: nextPage,
            filters: curr.activeFilters,
          );

          emit(
            result.customers.isEmpty
                ? curr.copyWith(hasReachedMax: true)
                : curr.copyWith(
                    customers: List.of(curr.customers)..addAll(result.customers),
                    currentPage: nextPage,
                    hasReachedMax: result.customers.length < 100,
                  ),
          );
        } catch (e) {
          emit(CustomerListError(e.toString()));
        }
      }
    });
  }
}

class CustomerFilterOptionsBloc
    extends Bloc<CustomerListEvent, CustomerFilterOptionsState> {
  final GetCustomerFilterOptions getCustomerFilterOptions;

  CustomerFilterOptionsBloc({required this.getCustomerFilterOptions})
      : super(CustomerFiltersInitial()) {
    on<LoadCustomerFilterOptionsEvent>((event, emit) async {
      emit(CustomerFiltersLoading());
      try {
        final opts = await getCustomerFilterOptions.call(
          AppGlobals.instance.shopfront ?? "",
        );

        emit(
          CustomerFiltersLoaded(
            states: opts['State'] ?? [],
            suburbs: opts['Suburb'] ?? [],
            postcodes: opts['Postcode'] ?? [],
          ),
        );
      } catch (e) {
        emit(CustomerFiltersError(e.toString()));
      }
    });
  }
}

class FetchCustomerBloc extends Bloc<FetchCustomerEvents, FetchCustomerStates> {
  final FetchCustomerData fetchCustomerData;

  FetchCustomerBloc({required this.fetchCustomerData}) : super(FetchCustomerInitial()) {
    on<StartCustomerSyncEvent>(_onStartCustomerSyncEvent);
  }

  Future<void> _onStartCustomerSyncEvent(
    StartCustomerSyncEvent event,
    Emitter<FetchCustomerStates> emit,
  ) async {
    if (state is FetchCustomerProgress) return;

    emit(
      FetchCustomerProgress(
        currentCount: 0,
        totalCount: 1,
        message: "Initializing connection...",
      ),
    );

    try {
      await emit.forEach<CustomerSyncStatus>(
        fetchCustomerData(event.ipAddress, event.username, event.password),
        onData: (status) {
          return FetchCustomerProgress(
            currentCount: status.processed,
            totalCount: status.total,
            message: status.message,
          );
        },
      );

      emit(FetchCustomerSuccess());
    } catch (e) {
      emit(FetchCustomerFailure(errorMessage: e.toString()));
    }
  }
}
