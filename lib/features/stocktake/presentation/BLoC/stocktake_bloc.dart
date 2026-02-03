import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rmstock_scanner/features/stocktake/domain/use_cases/backup_stocktake.dart';
import 'package:rmstock_scanner/features/stocktake/domain/use_cases/commit_stocktake.dart';
import 'package:rmstock_scanner/features/stocktake/domain/use_cases/fetch_counted_stock_by_id.dart';
import 'package:rmstock_scanner/features/stocktake/domain/use_cases/fetch_counting_stock.dart';
import 'package:rmstock_scanner/features/stocktake/domain/use_cases/fetch_sessions.dart';
import 'package:rmstock_scanner/features/stocktake/domain/use_cases/fetch_sesstion_items.dart';
import 'package:rmstock_scanner/features/stocktake/domain/use_cases/fetch_stocktake_audit_report.dart';
import 'package:rmstock_scanner/features/stocktake/domain/use_cases/fetch_stocktake_page.dart';
import 'package:rmstock_scanner/features/stocktake/domain/use_cases/load_backup_sessions.dart';
import 'package:rmstock_scanner/features/stocktake/domain/use_cases/restore_backup_session.dart';
import 'package:rmstock_scanner/features/stocktake/domain/use_cases/send_final_stocktake_to_rm.dart';
import 'package:rmstock_scanner/features/stocktake/domain/use_cases/update_stock_count.dart';
import 'package:rmstock_scanner/features/stocktake/models/stocktake_model.dart';
import 'package:rmstock_scanner/features/stocktake/presentation/BLoC/stocktake_events.dart';
import 'package:rmstock_scanner/features/stocktake/presentation/BLoC/stocktake_states.dart';

import '../../domain/use_cases/count_and_save_to_localdb.dart';

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

class StockDetailsBloc extends Bloc<StocktakeEvent, StockFetchingStates> {
  final FetchCountedStockById fetchCountedStockById;

  StockDetailsBloc({required this.fetchCountedStockById})
    : super(StockDetailsInitial()) {
    on<FetchStockDetailsByID>(_onFetchStockDetailsByID);
  }

  Future<void> _onFetchStockDetailsByID(
    FetchStockDetailsByID event,
    Emitter<StockFetchingStates> emit,
  ) async {
    emit(StockDetailsLoading());
    try {
      final stockResponse = await fetchCountedStockById(event.stockId);

      if (stockResponse == null) {
        emit(
          StockDetailsError(
            "Stock not found! Please check in Stock Lookup screen to see whether you have loaded your stock!",
          ),
        );
      } else {
        emit(StockDetailsLoaded(stockResponse, event.qty));
      }
    } catch (error) {
      emit(StockDetailsError("Error fetching stock: $error"));
    }
  }
}

//Stock count upate bloc
class StockCountUpdateBloc
    extends Bloc<StocktakeEvent, StockCountUpdateStates> {
  final UpdateStockCount updateStockCount;

  StockCountUpdateBloc({required this.updateStockCount})
    : super(StockCountUpdateInitial()) {
    on<UpdateStockCountEvent>(_onUpdateStockCountEvent);
  }

  Future<void> _onUpdateStockCountEvent(
    UpdateStockCountEvent event,
    Emitter<StockCountUpdateStates> emit,
  ) async {
    emit(StockCountUpdateInitial());
    try {
      if (event.qty.isEmpty) {
        emit(StockCountUpdateError("Counting quantity cannot be empty!"));
      }

      await updateStockCount(event.stock, event.qty);

      emit(StockCountUpdated("Stock count updated successfully!"));
    } catch (error) {
      emit(StockCountUpdateError("Error updating count: $error"));
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
  final FetchStocktakePage fetchStocktakePage;

  int _pageIndex = 0;
  final int _pageSize = 50;
  String _query = "";

  FetchingStocktakeListBloc({required this.fetchStocktakePage})
    : super(LoadingStocktakeList()) {
    on<FetchStocktakeListEvent>(_onFetch);
    on<NextStocktakePageEvent>(_onNext);
    on<PrevStocktakePageEvent>(_onPrev);
  }

  Future<void> _onFetch(
    FetchStocktakeListEvent event,
    Emitter<StocktakeListStates> emit,
  ) async {
    try {
      emit(LoadingStocktakeList());

      // If caller provided a query, update it
      if (event.query != null) {
        final incoming = event.query!.trim();
        final changed = incoming != _query;
        _query = incoming;

        // If query changed, always reset to page 0
        if (changed) _pageIndex = 0;
      }

      if (event.reset) _pageIndex = 0;

      final result = await fetchStocktakePage(
        pageIndex: _pageIndex,
        pageSize: _pageSize,
        query: _query,
      );

      // If current page becomes empty (e.g. after deletions) move back one page
      if (result.items.isEmpty && _pageIndex > 0) {
        _pageIndex--;
        final retry = await fetchStocktakePage(
          pageIndex: _pageIndex,
          pageSize: _pageSize,
          query: _query,
        );

        emit(
          StocktakeListLoaded(
            stocktakeList: retry.items,
            totalCount: retry.totalCount,
            pageIndex: _pageIndex,
            pageSize: _pageSize,
            query: _query,
          ),
        );
        return;
      }

      emit(
        StocktakeListLoaded(
          stocktakeList: result.items,
          totalCount: result.totalCount,
          pageIndex: _pageIndex,
          pageSize: _pageSize,
          query: _query,
        ),
      );
    } catch (e) {
      emit(StocktakeListError(e.toString()));
    }
  }

  void _onNext(
    NextStocktakePageEvent event,
    Emitter<StocktakeListStates> emit,
  ) {
    final s = state;
    if (s is StocktakeListLoaded && s.hasNext) {
      _pageIndex++;
      add(FetchStocktakeListEvent()); // keeps current _query
    }
  }

  void _onPrev(
    PrevStocktakePageEvent event,
    Emitter<StocktakeListStates> emit,
  ) {
    final s = state;
    if (s is StocktakeListLoaded && s.hasPrev) {
      _pageIndex--;
      add(FetchStocktakeListEvent()); // keeps current _query
    }
  }
}

// class FetchingStocktakeListBloc
//     extends Bloc<StocktakeEvent, StocktakeListStates> {
//   final FetchAllStocktakeList fetchAllStocktakeList;

//   FetchingStocktakeListBloc({required this.fetchAllStocktakeList})
//     : super(StocktakeListInitial()) {
//     on<FetchStocktakeListEvent>(_onFetchStocktakeList);
//   }

//   Future<void> _onFetchStocktakeList(
//     FetchStocktakeListEvent event,
//     Emitter<StocktakeListStates> emit,
//   ) async {
//     emit(LoadingStocktakeList());
//     try {
//       final List<CountedStockVO> stocktakeList = await fetchAllStocktakeList();

//       emit(StocktakeListLoaded(stocktakeList));
//     } catch (error) {
//       emit(StocktakeListError("Error fetching stocktake list: $error"));
//     }
//   }
// }

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
      if (error is String) {
        emit(ErrorCommitingStocktake("Error commiting stocktake list: $error"));
      } else {
        var e = error as dynamic;

        emit(
          ErrorCommitingStocktake(
            "Error commiting stocktake list: ${e.message.toString()}",
          ),
        );
      }
    }
  }
}

//backup
class BackupStocktakeBloc extends Bloc<StocktakeEvent, BackUpStocktakeStates> {
  final BackupStocktake backupStocktake;

  BackupStocktakeBloc({required this.backupStocktake})
    : super(BackupStocktakeInitial()) {
    on<BackUpStocktakeEvent>(_onBackupStocktake);
  }

  Future<void> _onBackupStocktake(
    BackUpStocktakeEvent event,
    Emitter<BackUpStocktakeStates> emit,
  ) async {
    emit(LoadingToBackupStocktake());
    try {
      await backupStocktake();

      emit(BackedUpStocktake("Stocktake Backed Up to Shared Folder!"));
    } catch (error) {
      if (error is String) {
        emit(ErrorBackupStocktake("Error backing up stocktake list: $error"));
      } else {
        var e = error as dynamic;

        emit(
          ErrorBackupStocktake(
            "Error backing up stocktake list: ${e.message.toString()}",
          ),
        );
      }
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

      emit(
        SentStocktakeToRM(
          "Stocktake data sent to RetailManager! Please navigate to Stock Management -> Stocktake -> Run Discrepancy Report and Commit the Stocktake.",
        ),
      );
    } catch (error) {
      emit(ErrorSendingStocktake("Error sending stocktake list: $error"));
    }
  }
}

class StocktakeHistoryBloc extends Bloc<StocktakeEvent, StocktakeHistoryState> {
  final FetchStocktakeHistorySessions fetchSessions;
  final FetchStocktakeHistoryItems fetchItems;

  StocktakeHistoryBloc({required this.fetchSessions, required this.fetchItems})
    : super(StocktakeHistoryInitial()) {
    on<LoadHistorySessionsEvent>(_onLoadSessions);
    on<LoadHistoryItemsEvent>(_onLoadItems);
  }

  Future<void> _onLoadSessions(
    LoadHistorySessionsEvent event,
    Emitter<StocktakeHistoryState> emit,
  ) async {
    emit(StocktakeHistoryLoading());
    try {
      final sessions = await fetchSessions();
      emit(StocktakeHistorySessionsLoaded(sessions));
    } catch (e) {
      emit(StocktakeHistoryError(e.toString()));
    }
  }

  Future<void> _onLoadItems(
    LoadHistoryItemsEvent event,
    Emitter<StocktakeHistoryState> emit,
  ) async {
    emit(StocktakeHistoryLoading());
    try {
      final items = await fetchItems(sessionId: event.sessionId);
      emit(StocktakeHistoryItemsLoaded(event.sessionId, items));
    } catch (e) {
      emit(StocktakeHistoryError(e.toString()));
    }
  }
}


//Backup
class BackupRestoreBloc extends Bloc<BackupRestoreEvent, BackupRestoreState> {
  final LoadBackupSessions loadSessions;
  final RestoreBackupSession restoreSession;

  BackupRestoreBloc({
    required this.loadSessions,
    required this.restoreSession,
  }) : super(BackupRestoreInitial()) {
    on<LoadBackupSessionsEvent>(_onLoad);
    on<RestoreBackupSessionEvent>(_onRestore);
  }

  Future<void> _onLoad(
    LoadBackupSessionsEvent event,
    Emitter<BackupRestoreState> emit,
  ) async {
    emit(BackupRestoreLoading());
    try {
      final sessions = await loadSessions();
      emit(BackupRestoreSessionsLoaded(sessions));
    } catch (e) {
      emit(BackupRestoreError(e.toString()));
    }
  }

  Future<void> _onRestore(
    RestoreBackupSessionEvent event,
    Emitter<BackupRestoreState> emit,
  ) async {
    emit(BackupRestoreRestoring());
    try {
      await restoreSession(event.session);
      emit(BackupRestoreDone("Backup restored into Stocktake list."));
    } catch (e) {
      emit(BackupRestoreError(e.toString()));
    }
  }
}
