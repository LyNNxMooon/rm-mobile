import '../../../../entities/vos/filter_criteria.dart';

abstract class CustomerListEvent {}

class FetchFirstCustomerPageEvent extends CustomerListEvent {
  final String query;
  final String filterColumn;
  final String sortColumn;
  final FilterCriteria? filters;
  final bool shouldToggleSort;

  FetchFirstCustomerPageEvent({
    this.query = "",
    this.filterColumn = "surname",
    this.sortColumn = "surname",
    this.filters,
    this.shouldToggleSort = false,
  });
}

class LoadMoreCustomersEvent extends CustomerListEvent {}

class LoadCustomerFilterOptionsEvent extends CustomerListEvent {}

abstract class FetchCustomerEvents {}

class StartCustomerSyncEvent extends FetchCustomerEvents {
  final String ipAddress;
  final String? username;
  final String? password;

  StartCustomerSyncEvent({required this.ipAddress, this.username, this.password});
}

abstract class StaffDetailEvents {}

class LoadStaffDetailsEvent extends StaffDetailEvents {
  final int openedId;
  final int ownerId;

  LoadStaffDetailsEvent({required this.openedId, required this.ownerId});
}
