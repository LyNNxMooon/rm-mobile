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
