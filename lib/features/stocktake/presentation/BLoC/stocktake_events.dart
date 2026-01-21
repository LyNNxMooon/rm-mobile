import 'package:rmstock_scanner/entities/vos/stock_vo.dart';
import 'package:rmstock_scanner/features/stocktake/presentation/BLoC/stocktake_states.dart';

abstract class StocktakeEvent {}

class FetchStockDetails extends StocktakeEvent {
  final String barcode;

  FetchStockDetails({required this.barcode});
}

class ResetStocktakeEvent extends StocktakeEvent {
  final ScannerStates targetState;
  ResetStocktakeEvent(this.targetState);
}

class Stocktake extends StocktakeEvent {
  final StockVO stock;
  final String qty;

  Stocktake({required this.stock, required this.qty});
}

class FetchStocktakeListEvent extends StocktakeEvent {}

class CommittingStocktakeEvent extends StocktakeEvent {}
