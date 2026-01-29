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

  RequestThumbnailEvent({required this.stockId, required this.pictureFileName});
}

class RequestFullImageEvent extends StockListEvent {
  final num stockId;
  final String pictureFileName;

  RequestFullImageEvent({required this.stockId, required this.pictureFileName});
}

//Image uploading
abstract class StockImageUploadEvent {}

class UploadStockImageEvent extends StockImageUploadEvent {
  final int stockId;
  final String imagePath;

  UploadStockImageEvent({required this.stockId, required this.imagePath});
}
