import '../vos/stock_vo.dart';

class PaginatedStockResult {
  final List<StockVO> items;
  final int totalCount;

  PaginatedStockResult(this.items, this.totalCount);
}
