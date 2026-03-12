import 'package:rmstock_scanner/entities/vos/filter_criteria.dart';
import 'package:rmstock_scanner/entities/response/staff_detail_response.dart';
import 'package:rmstock_scanner/entities/vos/search_mode.dart';
import 'package:rmstock_scanner/utils/enums.dart';

import '../../../../entities/vos/customer_vo.dart';

abstract class CustomerListState {}

class CustomerListInitial extends CustomerListState {}

class CustomerListLoading extends CustomerListState {}

class CustomerListLoaded extends CustomerListState {
  final List<CustomerVO> customers;
  final int totalCount;
  final bool hasReachedMax;

  final int currentPage;
  final String currentQuery;
  final String currentSortCol;
  final String currentFilterCol;
  final bool isAscending;
  final FilterCriteria? activeFilters;
  final SearchMode searchMode;

  CustomerListLoaded({
    required this.customers,
    required this.totalCount,
    this.hasReachedMax = false,
    required this.currentPage,
    required this.currentQuery,
    required this.currentSortCol,
    required this.currentFilterCol,
    required this.isAscending,
    this.activeFilters,
    this.searchMode = SearchMode.partial,
  });

  CustomerListLoaded copyWith({
    List<CustomerVO>? customers,
    int? totalCount,
    bool? hasReachedMax,
    int? currentPage,
    String? currentQuery,
    String? currentSortCol,
    String? currentFilterCol,
    bool? isAscending,
    FilterCriteria? activeFilters,
    SearchMode? searchMode,
  }) {
    return CustomerListLoaded(
      customers: customers ?? this.customers,
      totalCount: totalCount ?? this.totalCount,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      currentPage: currentPage ?? this.currentPage,
      currentQuery: currentQuery ?? this.currentQuery,
      currentSortCol: currentSortCol ?? this.currentSortCol,
      currentFilterCol: currentFilterCol ?? this.currentFilterCol,
      isAscending: isAscending ?? this.isAscending,
      activeFilters: activeFilters ?? this.activeFilters,
      searchMode: searchMode ?? this.searchMode,
    );
  }
}

class CustomerListError extends CustomerListState {
  final String message;
  CustomerListError(this.message);
}

abstract class CustomerFilterOptionsState {}

class CustomerFiltersInitial extends CustomerFilterOptionsState {}

class CustomerFiltersLoading extends CustomerFilterOptionsState {}

class CustomerFiltersError extends CustomerFilterOptionsState {
  final String message;
  CustomerFiltersError(this.message);
}

class CustomerFiltersLoaded extends CustomerFilterOptionsState {
  final List<String> states;
  final List<String> suburbs;
  final List<String> postcodes;

  CustomerFiltersLoaded({
    required this.states,
    required this.suburbs,
    required this.postcodes,
  });
}

abstract class FetchCustomerStates {}

class FetchCustomerInitial extends FetchCustomerStates {}

class FetchCustomerProgress extends FetchCustomerStates {
  final int currentCount;
  final int totalCount;
  final String message;

  FetchCustomerProgress({
    required this.currentCount,
    required this.totalCount,
    required this.message,
  });
}

class FetchCustomerSuccess extends FetchCustomerStates {
  final String message;

  FetchCustomerSuccess({this.message = "Customer sync completed successfully."});
}

class FetchCustomerFailure extends FetchCustomerStates {
  final String errorMessage;

  FetchCustomerFailure({required this.errorMessage});
}

abstract class StaffDetailState {}

class StaffDetailInitial extends StaffDetailState {}

class StaffDetailLoading extends StaffDetailState {}

class StaffDetailLoaded extends StaffDetailState {
  final StaffDetailInfo? openedBy;
  final StaffDetailInfo? ownerAccount;

  StaffDetailLoaded({this.openedBy, this.ownerAccount});
}

class StaffDetailError extends StaffDetailState {
  final String message;

  StaffDetailError(this.message);
}

abstract class CustomerUpdateState {}

class CustomerUpdateInitial extends CustomerUpdateState {}

class CustomerUpdateInProgress extends CustomerUpdateState {
  final CustomerEditSection section;

  CustomerUpdateInProgress(this.section);
}

class CustomerUpdateSuccess extends CustomerUpdateState {
  final CustomerEditSection section;
  final String message;

  CustomerUpdateSuccess({required this.section, required this.message});
}

class CustomerUpdateFailure extends CustomerUpdateState {
  final CustomerEditSection section;
  final String message;

  CustomerUpdateFailure({required this.section, required this.message});
}
