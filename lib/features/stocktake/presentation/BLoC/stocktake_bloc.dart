import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rmstock_scanner/entities/vos/counted_stock_vo.dart';
import 'package:rmstock_scanner/features/stocktake/domain/use_cases/commit_stocktake.dart';
import 'package:rmstock_scanner/features/stocktake/domain/use_cases/fetch_counting_stock.dart';
import 'package:rmstock_scanner/features/stocktake/presentation/BLoC/stocktake_events.dart';
import 'package:rmstock_scanner/features/stocktake/presentation/BLoC/stocktake_states.dart';

import '../../domain/use_cases/count_and_save_to_localDb.dart';
import '../../domain/use_cases/fetch_all_stocktake_list.dart';

class ScannerBloc extends Bloc<StocktakeEvent, ScannerStates> {
  final FetchCountingStock fetchCountingStock;

  ScannerBloc({required this.fetchCountingStock}) : super(ScannerInitial()) {
    on<FetchStockDetails>(_onFetchStockDetails);

    on<ResetStocktakeEvent>((event, emit) {
      emit(event.targetState); // Instantly switches to the provided state
    });
  }

  Future<void> _onFetchStockDetails(
    FetchStockDetails event,
    Emitter<ScannerStates> emit,
  ) async {
    emit(StockLoading());
    try {
      final stockResponse = await fetchCountingStock(event.barcode);

      if (stockResponse == null) {
        emit(
          StockError(
            "Stock not found! Please check in Stock Lookup screen to see whether you have loaded your stock!",
          ),
        );
      } else {
        emit(StockLoaded(stockResponse));
      }
    } catch (error) {
      emit(StockError("Error fetching stock: $error"));
    }
  }
}

//Stocktaking
class StocktakeBloc extends Bloc<StocktakeEvent, StocktakeStates> {
  final CountAndSaveToLocaldb countAndSaveToLocaldb;

  StocktakeBloc({required this.countAndSaveToLocaldb})
    : super(StocktakeInitial()) {
    on<Stocktake>(_onStocktake);
  }

  Future<void> _onStocktake(
    Stocktake event,
    Emitter<StocktakeStates> emit,
  ) async {
    emit(StocktakeLoading());
    try {
      await countAndSaveToLocaldb(qty: event.qty, stock: event.stock);

      emit(StockTaken());
    } catch (error) {
      emit(StocktakeError("Error stocktake: $error"));
    }
  }
}

class FetchingStocktakeListBloc
    extends Bloc<StocktakeEvent, StocktakeListStates> {
  final FetchAllStocktakeList fetchAllStocktakeList;

  FetchingStocktakeListBloc({required this.fetchAllStocktakeList})
    : super(StocktakeListInitial()) {
    on<FetchStocktakeListEvent>(_onFetchStocktakeList);
  }

  Future<void> _onFetchStocktakeList(
    FetchStocktakeListEvent event,
    Emitter<StocktakeListStates> emit,
  ) async {
    emit(LoadingStocktakeList());
    try {
      final List<CountedStockVO> stocktakeList = await fetchAllStocktakeList();

      emit(StocktakeListLoaded(stocktakeList));
    } catch (error) {
      emit(StocktakeListError("Error fetching stocktake list: $error"));
    }
  }
}

class CommittingStocktakeBloc
    extends Bloc<StocktakeEvent, CommitingStocktakeStates> {
  final CommitStocktake commitStocktake;

  CommittingStocktakeBloc({required this.commitStocktake})
    : super(CommitingStocktakeInitial()) {
    on<CommittingStocktakeEvent>(_onCommitingStocktake);
  }

  Future<void> _onCommitingStocktake(
    CommittingStocktakeEvent event,
    Emitter<CommitingStocktakeStates> emit,
  ) async {
    emit(LoadingToCommitStocktake());
    try {
      await commitStocktake();

      emit(
        CommittedStocktake("Stocktake committed to Lan Folder Successfully!"),
      );
    } catch (error) {
      emit(ErrorCommitingStocktake("Error commiting stocktake list: $error"));
    }
  }
}
