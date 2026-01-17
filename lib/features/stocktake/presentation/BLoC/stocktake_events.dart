import 'package:rmstock_scanner/entities/vos/stock_vo.dart';

abstract class StocktakeEvent {}

class FetchStockDetails extends StocktakeEvent {
  final String barcode;

  FetchStockDetails({required this.barcode});
}

class Stocktake extends StocktakeEvent {
  final StockVO stock;
  final String qty;

  Stocktake({required this.stock, required this.qty});
}

class FetchStocktakeListEvent extends StocktakeEvent {}

class CommittingStocktakeEvent extends StocktakeEvent {}
