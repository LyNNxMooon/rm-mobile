import 'package:rmstock_scanner/entities/vos/counted_stock_vo.dart';

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
