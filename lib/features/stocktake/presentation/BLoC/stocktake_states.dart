import 'package:rmstock_scanner/entities/vos/counted_stock_vo.dart';
import 'package:rmstock_scanner/entities/vos/stocktake_history_session_row.dart';
import 'package:rmstock_scanner/features/stocktake/models/stocktake_model.dart';

import '../../../../entities/vos/stock_vo.dart';

abstract class ScannerStates {}

class ScannerInitial extends ScannerStates {}

class StockLoading extends ScannerStates {}

class StockError extends ScannerStates {
  final String message;
  StockError(this.message);
}

class StockLoaded extends ScannerStates {
  final StockVO stock;

  StockLoaded(this.stock);
}

//Stocktaking
abstract class StocktakeStates {}

class StocktakeInitial extends StocktakeStates {}

class StocktakeLoading extends StocktakeStates {}

class StocktakeError extends StocktakeStates {
  final String message;
  StocktakeError(this.message);
}

class StockTaken extends StocktakeStates {}

//Fetch all stocktake list
abstract class StocktakeListStates {}

class StocktakeListInitial extends StocktakeListStates {}

class LoadingStocktakeList extends StocktakeListStates {}

class StocktakeListLoaded extends StocktakeListStates {
  final List<CountedStockVO> stocktakeList;

  StocktakeListLoaded(this.stocktakeList);
}

class StocktakeListError extends StocktakeListStates {
  final String message;

  StocktakeListError(this.message);
}

//Committing Stocktake
abstract class CommitingStocktakeStates {}

class CommitingStocktakeInitial extends CommitingStocktakeStates {}

class LoadingToCommitStocktake extends CommitingStocktakeStates {}

class CommittedStocktake extends CommitingStocktakeStates {
  final String message;

  CommittedStocktake(this.message);
}

class ErrorCommitingStocktake extends CommitingStocktakeStates {
  final String message;

  ErrorCommitingStocktake(this.message);
}

//Stocktake Validation
abstract class StocktakeValidationState {}

class StocktakeValidationInitial extends StocktakeValidationState {}

class StocktakeValidationProgress extends StocktakeValidationState {
  final int current;
  final int total;
  final String message;

  StocktakeValidationProgress({
    required this.current,
    required this.total,
    required this.message,
  });

  double get percentage => total == 0 ? 0 : (current / total).clamp(0.0, 1.0);
}

class StocktakeValidationClear extends StocktakeValidationState {}

class StocktakeValidationHasAudits extends StocktakeValidationState {
  final List<AuditWithStockVO> rows;
  StocktakeValidationHasAudits(this.rows);
}

class StocktakeValidationError extends StocktakeValidationState {
  final String message;
  StocktakeValidationError(this.message);
}

//final commiting
abstract class SendingFinalStocktakeStates {}

class SendingFinalStocktakeInitial extends SendingFinalStocktakeStates {}

class LoadingToSendStocktake extends SendingFinalStocktakeStates {}

class SentStocktakeToRM extends SendingFinalStocktakeStates {
  final String message;

  SentStocktakeToRM(this.message);
}

class ErrorSendingStocktake extends SendingFinalStocktakeStates {
  final String message;

  ErrorSendingStocktake(this.message);
}

abstract class StocktakeHistoryState {}

class StocktakeHistoryInitial extends StocktakeHistoryState {}

class StocktakeHistoryLoading extends StocktakeHistoryState {}

class StocktakeHistorySessionsLoaded extends StocktakeHistoryState {
  final List<StocktakeHistorySessionRow> sessions;
  StocktakeHistorySessionsLoaded(this.sessions);
}

class StocktakeHistoryItemsLoaded extends StocktakeHistoryState {
  final String sessionId;
  final List<CountedStockVO> items;
  StocktakeHistoryItemsLoaded(this.sessionId, this.items);
}

class StocktakeHistoryError extends StocktakeHistoryState {
  final String message;
  StocktakeHistoryError(this.message);
}
