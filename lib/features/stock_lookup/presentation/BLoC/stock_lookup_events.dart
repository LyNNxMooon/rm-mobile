import '../../../../entities/vos/filter_criteria.dart';

abstract class StockListEvent {}

class FetchFirstPageEvent extends StockListEvent {
  final String query;
  final String filterColumn;
  final String sortColumn;
  final FilterCriteria? filters;
  final bool shouldToggleSort;

  FetchFirstPageEvent({
    this.query = "",
    this.filterColumn = "description",
    this.sortColumn = "description",
    this.filters,
    this.shouldToggleSort = false,
  });
}

class LoadMoreEvent extends StockListEvent {}

class LoadFilterOptionsEvent extends StockListEvent {}

class RequestThumbnailEvent extends StockListEvent {
  final num stockId;
  final String pictureFileName;
  final bool forceRefresh;

  RequestThumbnailEvent({
    required this.stockId,
    required this.pictureFileName,
    this.forceRefresh = false,
  });
}

class RequestFullImageEvent extends StockListEvent {
  final num stockId;
  final String pictureFileName;
  final bool forceRefresh;

  RequestFullImageEvent({
    required this.stockId,
    required this.pictureFileName,
    this.forceRefresh = false,
  });
}

//Image uploading
abstract class StockImageUploadEvent {}

class UploadStockImageEvent extends StockImageUploadEvent {
  final int stockId;
  final String imagePath;

  UploadStockImageEvent({required this.stockId, required this.imagePath});
}

//Stock update
abstract class StockUpdateEvent {}

class SubmitStockUpdateEvent extends StockUpdateEvent {
  final int stockId;
  final String description;
  final double sell;

  SubmitStockUpdateEvent({
    required this.stockId,
    required this.description,
    required this.sell,
  });
}
