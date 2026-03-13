import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rmstock_scanner/entities/response/staff_detail_response.dart';
import 'package:rmstock_scanner/features/customer_lookup/domain/entities/customer_sync_status.dart';
import 'package:rmstock_scanner/features/customer_lookup/domain/use_cases/fetch_customer_data.dart';
import 'package:rmstock_scanner/features/customer_lookup/domain/use_cases/get_customer_filter_options.dart';
import 'package:rmstock_scanner/features/customer_lookup/domain/use_cases/get_paginated_customers.dart';
import 'package:rmstock_scanner/features/customer_lookup/domain/use_cases/get_staff_detail.dart';
import 'package:rmstock_scanner/features/customer_lookup/domain/use_cases/update_customer_details.dart';
import 'package:rmstock_scanner/features/customer_lookup/domain/use_cases/get_pending_customer_updates.dart';
import 'package:rmstock_scanner/features/customer_lookup/domain/use_cases/get_pending_customer_updates_count.dart';
import 'package:rmstock_scanner/features/customer_lookup/domain/use_cases/send_pending_customer_updates.dart';
import 'package:rmstock_scanner/features/customer_lookup/domain/use_cases/resolve_customer_create_conflicts.dart';
import 'package:rmstock_scanner/features/customer_lookup/presentation/BLoC/customer_lookup_events.dart';
import 'package:rmstock_scanner/features/customer_lookup/presentation/BLoC/customer_lookup_states.dart';

import '../../../../utils/global_var_utils.dart';
import '../../../../local_db/local_db_dao.dart';

class CustomerListBloc extends Bloc<CustomerListEvent, CustomerListState> {
  final GetPaginatedCustomers getPaginatedCustomers;
  bool _isLoadingMore = false;

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
          searchMode: event.searchMode,
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
            searchMode: event.searchMode,
            matchedFields: result.matchedFields,
          ),
        );
      } catch (e) {
        emit(CustomerListError(e.toString()));
      }
    });

    on<LoadMoreCustomersEvent>((event, emit) async {
      if (state is CustomerListLoaded) {
        final curr = state as CustomerListLoaded;
        if (curr.hasReachedMax || _isLoadingMore) return;
        _isLoadingMore = true;

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
            searchMode: curr.searchMode,
          );

          emit(
            result.customers.isEmpty
                ? curr.copyWith(hasReachedMax: true)
                : curr.copyWith(
                    customers: List.of(curr.customers)..addAll(result.customers),
                    currentPage: nextPage,
                    hasReachedMax: result.customers.length < 100,
                    matchedFields: {...curr.matchedFields, ...result.matchedFields},
                  ),
          );
        } catch (e) {
          emit(CustomerListError(e.toString()));
        } finally {
          _isLoadingMore = false;
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

class StaffDetailBloc extends Bloc<StaffDetailEvents, StaffDetailState> {
  final GetStaffDetail getStaffDetail;

  StaffDetailBloc({required this.getStaffDetail}) : super(StaffDetailInitial()) {
    on<LoadStaffDetailsEvent>(_onLoadStaffDetails);
  }

  Future<void> _onLoadStaffDetails(
    LoadStaffDetailsEvent event,
    Emitter<StaffDetailState> emit,
  ) async {
    emit(StaffDetailLoading());

    StaffDetailInfo? openedBy;
    StaffDetailInfo? ownerAccount;
    String? errorMessage;

    if (event.openedId > 0) {
      try {
        final response = await getStaffDetail(event.openedId);
        openedBy = response.staff;
      } catch (e) {
        errorMessage = e.toString();
      }
    }

    if (event.ownerId > 0) {
      if (event.ownerId == event.openedId) {
        ownerAccount = openedBy;
      } else {
        try {
          final response = await getStaffDetail(event.ownerId);
          ownerAccount = response.staff;
        } catch (e) {
          errorMessage ??= e.toString();
        }
      }
    }

    if (openedBy == null && ownerAccount == null && errorMessage != null) {
      emit(StaffDetailError(errorMessage));
      return;
    }

    emit(StaffDetailLoaded(openedBy: openedBy, ownerAccount: ownerAccount));
  }
}

class CustomerUpdateBloc extends Bloc<CustomerUpdateEvent, CustomerUpdateState> {
  final UpdateCustomerDetails updateCustomerDetails;

  CustomerUpdateBloc({required this.updateCustomerDetails})
      : super(CustomerUpdateInitial()) {
    on<SubmitCustomerUpdateEvent>(_onSubmitCustomerUpdate);
  }

  Future<void> _onSubmitCustomerUpdate(
    SubmitCustomerUpdateEvent event,
    Emitter<CustomerUpdateState> emit,
  ) async {
    emit(CustomerUpdateInProgress(event.section));

    try {
      final response = await updateCustomerDetails(event.body);

      if (!response.success) {
        emit(
          CustomerUpdateFailure(
            section: event.section,
            message: response.message,
          ),
        );
        return;
      }

      emit(
        CustomerUpdateSuccess(
          section: event.section,
          message: response.message,
        ),
      );
    } catch (e) {
      emit(
        CustomerUpdateFailure(
          section: event.section,
          message: e.toString(),
        ),
      );
    }
  }
}

class PendingCustomerUpdatesBloc
    extends Bloc<PendingCustomerUpdatesEvent, PendingCustomerUpdatesState> {
  final GetPendingCustomerUpdatesCount getPendingCustomerUpdatesCount;
  final GetPendingCustomerUpdates getPendingCustomerUpdates;
  final SendPendingCustomerUpdates sendPendingCustomerUpdates;
  final ResolveCustomerCreateConflicts resolveCustomerCreateConflicts;
  bool _isSending = false;

  PendingCustomerUpdatesBloc({
    required this.getPendingCustomerUpdatesCount,
    required this.getPendingCustomerUpdates,
    required this.sendPendingCustomerUpdates,
    required this.resolveCustomerCreateConflicts,
  }) : super(PendingCustomerUpdatesInitial()) {
    on<LoadPendingCustomerUpdatesCountEvent>(_onLoadCount);
    on<LoadPendingCustomerUpdatesEvent>(_onLoadList);
    on<SendPendingCustomerUpdatesEvent>(_onSend);
    on<ResolveCustomerCreateConflictsEvent>(_onResolveConflicts);
  }

  Future<String> _resolveShopfront() async {
    final fromGlobals = AppGlobals.instance.shopfront ?? "";
    if (fromGlobals.trim().isNotEmpty) return fromGlobals.trim();
    return (await LocalDbDAO.instance.getShopfrontName() ?? "").trim();
  }

  Future<void> _onLoadCount(
    LoadPendingCustomerUpdatesCountEvent event,
    Emitter<PendingCustomerUpdatesState> emit,
  ) async {
    try {
      if (_isSending) return;
      final shopfront = await _resolveShopfront();
      if (shopfront.isEmpty) {
        emit(PendingCustomerUpdatesCountLoaded(0));
        return;
      }
      final count = await getPendingCustomerUpdatesCount(shopfront);
      emit(PendingCustomerUpdatesCountLoaded(count));
    } catch (e) {
      emit(PendingCustomerUpdatesError(e.toString()));
    }
  }

  Future<void> _onLoadList(
    LoadPendingCustomerUpdatesEvent event,
    Emitter<PendingCustomerUpdatesState> emit,
  ) async {
    if (_isSending) return;
    emit(PendingCustomerUpdatesLoading());
    try {
      final shopfront = await _resolveShopfront();
      if (shopfront.isEmpty) {
        emit(PendingCustomerUpdatesLoaded([]));
        return;
      }
      final updates = await getPendingCustomerUpdates(shopfront);
      emit(PendingCustomerUpdatesLoaded(updates));
    } catch (e) {
      emit(PendingCustomerUpdatesError(e.toString()));
    }
  }

  Future<void> _onSend(
    SendPendingCustomerUpdatesEvent event,
    Emitter<PendingCustomerUpdatesState> emit,
  ) async {
    _isSending = true;
    emit(PendingCustomerUpdatesLoading());
    try {
      final shopfront = await _resolveShopfront();
      if (shopfront.isEmpty) {
        _isSending = false;
        emit(PendingCustomerUpdatesError("Missing shopfront setup."));
        return;
      }
      final result = await sendPendingCustomerUpdates(shopfront);
      final bool hasConflicts = result['hasConflicts'] == true;
      final String message = result['message']?.toString() ??
          (hasConflicts
              ? 'Customer create conflicts need review.'
              : 'Pending customer updates sent.');

      emit(
        PendingCustomerUpdatesSent(
          message: message,
          hasConflicts: hasConflicts,
        ),
      );
      _isSending = false;
    } catch (e) {
      _isSending = false;
      emit(PendingCustomerUpdatesError(e.toString()));
    }
  }

  Future<void> _onResolveConflicts(
    ResolveCustomerCreateConflictsEvent event,
    Emitter<PendingCustomerUpdatesState> emit,
  ) async {
    emit(PendingCustomerUpdatesLoading());
    try {
      final shopfront = await _resolveShopfront();
      if (shopfront.isEmpty) {
        emit(PendingCustomerUpdatesError("Missing shopfront setup."));
        return;
      }
      await resolveCustomerCreateConflicts(
        shopfront: shopfront,
        duplicate: event.duplicate,
      );

      final updates = await getPendingCustomerUpdates(shopfront);
      emit(PendingCustomerUpdatesLoaded(updates, showDialog: false));
    } catch (e) {
      emit(PendingCustomerUpdatesError(e.toString()));
    }
  }
}
