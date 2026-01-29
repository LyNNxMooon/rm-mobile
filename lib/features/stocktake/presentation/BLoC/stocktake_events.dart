import 'package:rmstock_scanner/entities/vos/stock_vo.dart';
import 'package:rmstock_scanner/features/stocktake/models/stocktake_model.dart';
import 'package:rmstock_scanner/features/stocktake/presentation/BLoC/stocktake_states.dart';

abstract class StocktakeEvent {}

class FetchStockDetails extends StocktakeEvent {
  final String barcode;

  FetchStockDetails({required this.barcode});
}

class FetchStockDetailsByID extends StocktakeEvent {
  final int stockId;
  final num qty;

  FetchStockDetailsByID({required this.stockId, required this.qty});
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

class StartStocktakeValidationEvent extends StocktakeEvent {}

class SendingFinalStocktakeEvent extends StocktakeEvent {
  final List<AuditWithStockVO> auditData;

  SendingFinalStocktakeEvent(this.auditData);
}

class LoadHistorySessionsEvent extends StocktakeEvent {}

class LoadHistoryItemsEvent extends StocktakeEvent {
  final String sessionId;
  LoadHistoryItemsEvent(this.sessionId);
}
