import '../../../../entities/vos/filter_criteria.dart';
import '../../../../entities/vos/search_mode.dart';
import '../../../../utils/enums.dart';

abstract class CustomerListEvent {}

class FetchFirstCustomerPageEvent extends CustomerListEvent {
  final String query;
  final String filterColumn;
  final String sortColumn;
  final FilterCriteria? filters;
  final bool shouldToggleSort;
  final SearchMode searchMode;

  FetchFirstCustomerPageEvent({
    this.query = "",
    this.filterColumn = "surname",
    this.sortColumn = "surname",
    this.filters,
    this.shouldToggleSort = false,
    this.searchMode = SearchMode.partial,
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

abstract class CustomerBalanceEvents {}

class LoadCustomerBalanceEvent extends CustomerBalanceEvents {
  final int customerId;

  LoadCustomerBalanceEvent({required this.customerId});
}

abstract class CustomerUpdateEvent {}

class SubmitCustomerUpdateEvent extends CustomerUpdateEvent {
  final Map<String, dynamic> body;
  final CustomerEditSection section;

  SubmitCustomerUpdateEvent({required this.body, required this.section});
}

// Pending customer updates
abstract class PendingCustomerUpdatesEvent {}

class LoadPendingCustomerUpdatesCountEvent extends PendingCustomerUpdatesEvent {}

class LoadPendingCustomerUpdatesEvent extends PendingCustomerUpdatesEvent {
  final bool showDialog;
  LoadPendingCustomerUpdatesEvent({this.showDialog = true});
}

class SendPendingCustomerUpdatesEvent extends PendingCustomerUpdatesEvent {}

class SendPendingCustomerCreationsEvent extends PendingCustomerUpdatesEvent {}

class DeletePendingCustomerUpdateEvent extends PendingCustomerUpdatesEvent {
  final int id;
  DeletePendingCustomerUpdateEvent({required this.id});
}

class DeletePendingCustomerCreationEvent extends PendingCustomerUpdatesEvent {
  final int id;
  DeletePendingCustomerCreationEvent({required this.id});
}

class DeleteAllPendingCustomerItemsEvent extends PendingCustomerUpdatesEvent {
  final List<int> updateIds;
  final List<int> creationIds;

  DeleteAllPendingCustomerItemsEvent({
    required this.updateIds,
    required this.creationIds,
  });
}

class ResolveCustomerCreateConflictsEvent extends PendingCustomerUpdatesEvent {
  final bool duplicate;
  ResolveCustomerCreateConflictsEvent({required this.duplicate});
}
