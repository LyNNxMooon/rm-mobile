import 'package:rmstock_scanner/entities/vos/stock_vo.dart';

class StockSearchResult {
  final StockVO? stock;
  final List<StockVO> duplicates;
  final bool notFound;

  const StockSearchResult({
    required this.stock,
    required this.duplicates,
    required this.notFound,
  });

  factory StockSearchResult.found(StockVO s) =>
      StockSearchResult(stock: s, duplicates: const [], notFound: false);

  factory StockSearchResult.duplicates(List<StockVO> list) =>
      StockSearchResult(stock: null, duplicates: list, notFound: false);

  factory StockSearchResult.none() =>
      const StockSearchResult(stock: null, duplicates: [], notFound: true);
}
