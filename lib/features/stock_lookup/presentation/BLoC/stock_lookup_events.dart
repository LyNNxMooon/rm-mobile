abstract class StockListEvent {}

class FetchFirstPageEvent extends StockListEvent {
  final String query;
  final String filterColumn;
  final String sortColumn;
  FetchFirstPageEvent({
    this.query = "",
    this.filterColumn = "description",
    this.sortColumn = "description",
  });
}

class LoadMoreEvent extends StockListEvent {}

class LoadFilterOptionsEvent extends StockListEvent {}
