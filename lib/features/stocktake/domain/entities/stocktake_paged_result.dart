import 'package:rmstock_scanner/entities/vos/counted_stock_vo.dart';

class StocktakePagedResult {
  final List<CountedStockVO> items;
  final int totalCount;

  StocktakePagedResult({required this.items, required this.totalCount});
}
