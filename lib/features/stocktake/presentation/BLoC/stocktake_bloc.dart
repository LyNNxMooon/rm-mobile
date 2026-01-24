import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rmstock_scanner/entities/vos/counted_stock_vo.dart';
import 'package:rmstock_scanner/features/stocktake/domain/use_cases/commit_stocktake.dart';
import 'package:rmstock_scanner/features/stocktake/domain/use_cases/fetch_counting_stock.dart';
import 'package:rmstock_scanner/features/stocktake/domain/use_cases/fetch_stocktake_audit_report.dart';
import 'package:rmstock_scanner/features/stocktake/domain/use_cases/send_final_stocktake_to_rm.dart';
import 'package:rmstock_scanner/features/stocktake/models/stocktake_model.dart';
import 'package:rmstock_scanner/features/stocktake/presentation/BLoC/stocktake_events.dart';
import 'package:rmstock_scanner/features/stocktake/presentation/BLoC/stocktake_states.dart';

import '../../domain/use_cases/count_and_save_to_localdb.dart';
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
    if (event.stock.staticQuantity || event.stock.package) {
      emit(StocktakeError("Static/Package items cannot be counted!"));
      return; // Stop execution here
    }

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

      emit(CommittedStocktake("Stocktake data sent for validation!"));
    } catch (error) {
      emit(ErrorCommitingStocktake("Error commiting stocktake list: $error"));
    }
  }
}

class StocktakeValidationBloc
    extends Bloc<StocktakeEvent, StocktakeValidationState> {
  final FetchStocktakeAuditReport fetchStocktakeAuditReport;

  StocktakeValidationBloc({required this.fetchStocktakeAuditReport})
    : super(StocktakeValidationInitial()) {
    on<StartStocktakeValidationEvent>(_onStart);
  }

  Future<void> _onStart(
    StartStocktakeValidationEvent event,
    Emitter<StocktakeValidationState> emit,
  ) async {
    emit(
      StocktakeValidationProgress(
        current: 0,
        total: 60,
        message: "Waiting for agent...",
      ),
    );

    try {
      await emit.forEach<AuditSyncStatus>(
        fetchStocktakeAuditReport(),
        onData: (status) {
          // progress messages
          if (status.rows == null) {
            return StocktakeValidationProgress(
              current: status.processed,
              total: status.total,
              message: status.message,
            );
          }

          // finished
          if (status.rows!.isEmpty) {
            return StocktakeValidationClear();
          } else {
            return StocktakeValidationHasAudits(status.rows!);
          }
        },
        onError: (error, stackTrace) {
          return StocktakeValidationError(error.toString());
        },
      );
    } catch (e) {
      emit(StocktakeValidationError(e.toString()));
    }
  }
}

class SendingFinalStocktakeBloc
    extends Bloc<StocktakeEvent, SendingFinalStocktakeStates> {
  final SendFinalStocktakeToRm sendFinalStocktakeToRm;

  SendingFinalStocktakeBloc({required this.sendFinalStocktakeToRm})
    : super(SendingFinalStocktakeInitial()) {
    on<SendingFinalStocktakeEvent>(_onSendingStocktake);
  }

  Future<void> _onSendingStocktake(
    SendingFinalStocktakeEvent event,
    Emitter<SendingFinalStocktakeStates> emit,
  ) async {
    emit(LoadingToSendStocktake());
    try {
      await sendFinalStocktakeToRm(event.auditData);

      emit(SentStocktakeToRM("Stocktake data commited to RetailManager!"));
    } catch (error) {
      emit(ErrorSendingStocktake("Error sending stocktake list: $error"));
    }
  }
}
