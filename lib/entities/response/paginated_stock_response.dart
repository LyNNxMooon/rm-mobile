import '../vos/stock_vo.dart';

class PaginatedStockResult {
  final List<StockVO> items;
  final int totalCount;
  final Map<int, String> matchedFields; // stockId -> matched column name

  PaginatedStockResult(
    this.items,
    this.totalCount, {
    Map<int, String>? matchedFields,
  }) : matchedFields = matchedFields ?? {};
}
