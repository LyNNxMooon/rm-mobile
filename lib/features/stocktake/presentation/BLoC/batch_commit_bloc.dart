import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rmmobile/features/stocktake/domain/entities/batch_commit_entities.dart';
import 'package:rmmobile/features/stocktake/domain/entities/stocktake_audit_entities.dart';
import 'package:rmmobile/features/stocktake/domain/use_cases/batch_commit_stocktake.dart';
import 'package:rmmobile/features/stocktake/domain/use_cases/has_unsynced_stocktakes.dart';
import 'package:rmmobile/utils/global_var_utils.dart';

// ============================================================================
// EVENTS
// ============================================================================

abstract class BatchCommitEvent {}

/// Start the batch commit process
class StartBatchCommitEvent extends BatchCommitEvent {}

/// User decided how to handle audits for current batch
/// [applyAdjustments] = true means apply transaction movements to quantities
class ResolveBatchAuditsEvent extends BatchCommitEvent {
  final bool applyAdjustments;
  ResolveBatchAuditsEvent({required this.applyAdjustments});
}

/// User selected specific audits to apply (when using checkbox selection)
class ResolveBatchAuditsWithSelectionEvent extends BatchCommitEvent {
  final List<AuditWithStockVO> selectedAudits;
  ResolveBatchAuditsWithSelectionEvent({required this.selectedAudits});
}

/// Cancel the entire batch commit process
class CancelBatchCommitEvent extends BatchCommitEvent {}

// ============================================================================
// STATES
// ============================================================================

abstract class BatchCommitState {}

class BatchCommitInitial extends BatchCommitState {}

/// Preparing batches (loading items from DB, splitting)
class BatchCommitPreparing extends BatchCommitState {
  final String message;
  BatchCommitPreparing([this.message = "Preparing stocktake data..."]);
}

/// Processing batches - main progress state
class BatchCommitInProgress extends BatchCommitState {
  final BatchCommitProgress progress;
  BatchCommitInProgress(this.progress);
  
  int get currentBatchNumber => progress.currentBatchIndex + 1;
  int get totalBatches => progress.totalBatches;
  String get phaseDescription {
    final current = progress.currentBatch;
    if (current == null) return "Processing...";
    
    switch (current.phase) {
      case BatchPhase.pending:
        return "Waiting...";
      case BatchPhase.initCheck:
        return "Validating batch $currentBatchNumber of $totalBatches...";
      case BatchPhase.awaitingAuditDecision:
        return "Awaiting audit decision...";
      case BatchPhase.finalCommit:
        return "Committing batch $currentBatchNumber of $totalBatches...";
      case BatchPhase.completed:
        return "Batch $currentBatchNumber completed!";
      case BatchPhase.failed:
        return "Batch $currentBatchNumber failed";
    }
  }
}

/// Current batch has audits that need user decision
class BatchCommitAwaitingAuditDecision extends BatchCommitState {
  final BatchCommitProgress progress;
  final List<AuditWithStockVO> audits;
  
  BatchCommitAwaitingAuditDecision({
    required this.progress,
    required this.audits,
  });
  
  int get currentBatchNumber => progress.currentBatchIndex + 1;
  int get totalBatches => progress.totalBatches;
}

/// All batches completed successfully
class BatchCommitCompleted extends BatchCommitState {
  final int totalItems;
  final int totalBatches;
  final String message;
  
  BatchCommitCompleted({
    required this.totalItems,
    required this.totalBatches,
    required this.message,
  });
}

/// Batch commit failed
class BatchCommitFailed extends BatchCommitState {
  final String message;
  final BatchCommitProgress? progress;
  
  BatchCommitFailed(this.message, {this.progress});
}

/// No items to commit
class BatchCommitEmpty extends BatchCommitState {}

// ============================================================================
// BLOC
// ============================================================================

class BatchCommitBloc extends Bloc<BatchCommitEvent, BatchCommitState> {
  final BatchCommitStocktake batchCommitStocktake;
  final HasUnsyncedStocktakes hasUnsyncedStocktakes;

  List<StocktakeBatch> _batches = [];
  BatchCommitProgress? _currentProgress;
  List<AuditWithStockVO> _currentBatchAudits = [];

  BatchCommitBloc({
    required this.batchCommitStocktake,
    required this.hasUnsyncedStocktakes,
  }) : super(BatchCommitInitial()) {
    on<StartBatchCommitEvent>(_onStart);
    on<ResolveBatchAuditsEvent>(_onResolveAudits);
    on<ResolveBatchAuditsWithSelectionEvent>(_onResolveAuditsWithSelection);
    on<CancelBatchCommitEvent>(_onCancel);
  }

  Future<void> _onStart(
    StartBatchCommitEvent event,
    Emitter<BatchCommitState> emit,
  ) async {
    emit(BatchCommitPreparing());

    try {
      // Check if there are items to sync
      final shopfront = AppGlobals.instance.shopfront ?? "";
      final hasItems = await hasUnsyncedStocktakes(shopfront: shopfront);
      
      if (!hasItems) {
        emit(BatchCommitEmpty());
        return;
      }

      // Prepare batches
      emit(BatchCommitPreparing("Splitting items into batches..."));
      _batches = await batchCommitStocktake.prepareBatches();

      if (_batches.isEmpty) {
        emit(BatchCommitEmpty());
        return;
      }

      // Initialize progress tracking
      final totalItems = _batches.fold<int>(0, (sum, b) => sum + b.itemCount);
      final batchStatuses = List.generate(
        _batches.length,
        (i) => BatchStatus(batchIndex: i),
      );

      _currentProgress = BatchCommitProgress(
        totalItems: totalItems,
        totalBatches: _batches.length,
        currentBatchIndex: 0,
        batchStatuses: batchStatuses,
      );

      emit(BatchCommitInProgress(_currentProgress!));

      // Process first batch
      await _processCurrentBatch(emit);
    } catch (e) {
      emit(BatchCommitFailed(e.toString(), progress: _currentProgress));
    }
  }

  Future<void> _processCurrentBatch(Emitter<BatchCommitState> emit) async {
    if (_currentProgress == null) return;

    final batchIndex = _currentProgress!.currentBatchIndex;
    if (batchIndex >= _batches.length) {
      // All batches done
      emit(BatchCommitCompleted(
        totalItems: _currentProgress!.totalItems,
        totalBatches: _currentProgress!.totalBatches,
        message: "All ${_currentProgress!.totalItems} items committed successfully in ${_currentProgress!.totalBatches} batch(es)!",
      ));
      return;
    }

    final batch = _batches[batchIndex];

    try {
      // Phase: Init check
      _updateBatchStatus(batchIndex, BatchPhase.initCheck, "Running validation...");
      emit(BatchCommitInProgress(_currentProgress!));

      final audits = await batchCommitStocktake.initCheckBatch(batch);
      _currentBatchAudits = audits;

      if (audits.isNotEmpty) {
        // Has audits - need user decision
        _updateBatchStatus(
          batchIndex,
          BatchPhase.awaitingAuditDecision,
          "Awaiting decision",
          audits: audits,
        );
        emit(BatchCommitAwaitingAuditDecision(
          progress: _currentProgress!,
          audits: audits,
        ));
      } else {
        // No audits - proceed to commit
        await _commitCurrentBatch(emit, []);
      }
    } catch (e) {
      _updateBatchStatus(batchIndex, BatchPhase.failed, e.toString());
      emit(BatchCommitFailed(
        "Batch ${batchIndex + 1} failed: $e",
        progress: _currentProgress,
      ));
    }
  }

  Future<void> _onResolveAudits(
    ResolveBatchAuditsEvent event,
    Emitter<BatchCommitState> emit,
  ) async {
    if (_currentProgress == null) return;

    final auditsToApply = event.applyAdjustments ? _currentBatchAudits : <AuditWithStockVO>[];
    await _commitCurrentBatch(emit, auditsToApply);
  }

  Future<void> _onResolveAuditsWithSelection(
    ResolveBatchAuditsWithSelectionEvent event,
    Emitter<BatchCommitState> emit,
  ) async {
    if (_currentProgress == null) return;
    await _commitCurrentBatch(emit, event.selectedAudits);
  }

  Future<void> _commitCurrentBatch(
    Emitter<BatchCommitState> emit,
    List<AuditWithStockVO> auditsToApply,
  ) async {
    if (_currentProgress == null) return;

    final batchIndex = _currentProgress!.currentBatchIndex;
    final batch = _batches[batchIndex];

    try {
      // Phase: Final commit
      _updateBatchStatus(batchIndex, BatchPhase.finalCommit, "Committing...");
      emit(BatchCommitInProgress(_currentProgress!));

      await batchCommitStocktake.commitBatch(batch, auditsToApply);

      // Mark batch as completed
      _updateBatchStatus(batchIndex, BatchPhase.completed, "Completed!");
      _currentBatchAudits = [];

      // Move to next batch
      _currentProgress = _currentProgress!.copyWith(
        currentBatchIndex: batchIndex + 1,
      );

      emit(BatchCommitInProgress(_currentProgress!));

      // Process next batch (if any)
      await _processCurrentBatch(emit);
    } catch (e) {
      _updateBatchStatus(batchIndex, BatchPhase.failed, e.toString());
      emit(BatchCommitFailed(
        "Batch ${batchIndex + 1} commit failed: $e",
        progress: _currentProgress,
      ));
    }
  }

  void _updateBatchStatus(
    int batchIndex,
    BatchPhase phase,
    String message, {
    List<AuditWithStockVO>? audits,
  }) {
    if (_currentProgress == null) return;

    final statuses = List<BatchStatus>.from(_currentProgress!.batchStatuses);
    statuses[batchIndex] = statuses[batchIndex].copyWith(
      phase: phase,
      message: message,
      audits: audits,
    );

    _currentProgress = _currentProgress!.copyWith(batchStatuses: statuses);
  }

  void _onCancel(
    CancelBatchCommitEvent event,
    Emitter<BatchCommitState> emit,
  ) {
    _batches = [];
    _currentProgress = null;
    _currentBatchAudits = [];
    emit(BatchCommitInitial());
  }
}
