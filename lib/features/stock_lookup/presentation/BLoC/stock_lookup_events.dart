import '../../../../entities/vos/filter_criteria.dart';

abstract class StockListEvent {}

class FetchFirstPageEvent extends StockListEvent {
  final String query;
  final String filterColumn;
  final String sortColumn;
  final FilterCriteria? filters;
  FetchFirstPageEvent({
    this.query = "",
    this.filterColumn = "description",
    this.sortColumn = "description",
    this.filters,
  });
}

class LoadMoreEvent extends StockListEvent {}

class LoadFilterOptionsEvent extends StockListEvent {}
