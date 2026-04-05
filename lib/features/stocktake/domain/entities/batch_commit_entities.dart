import 'package:rmstock_scanner/entities/vos/counted_stock_vo.dart';
import 'package:rmstock_scanner/features/stocktake/domain/entities/stocktake_audit_entities.dart';

/// Represents a single batch of stocktake items to process
class StocktakeBatch {
  final int batchIndex;
  final int totalBatches;
  final List<CountedStockVO> items;

  StocktakeBatch({
    required this.batchIndex,
    required this.totalBatches,
    required this.items,
  });

  int get itemCount => items.length;
  bool get isLastBatch => batchIndex == totalBatches - 1;
}

/// Represents the current state of a batch being processed
enum BatchPhase {
  pending,
  initCheck,
  awaitingAuditDecision,
  finalCommit,
  completed,
  failed,
}

/// Tracks the status of a single batch
class BatchStatus {
  final int batchIndex;
  final BatchPhase phase;
  final String? message;
  final List<AuditWithStockVO>? audits;
  final String? errorMessage;

  BatchStatus({
    required this.batchIndex,
    this.phase = BatchPhase.pending,
    this.message,
    this.audits,
    this.errorMessage,
  });

  bool get isCompleted => phase == BatchPhase.completed;
  bool get isFailed => phase == BatchPhase.failed;
  bool get needsAuditDecision => phase == BatchPhase.awaitingAuditDecision;
  bool get hasAudits => audits != null && audits!.isNotEmpty;

  BatchStatus copyWith({
    BatchPhase? phase,
    String? message,
    List<AuditWithStockVO>? audits,
    String? errorMessage,
  }) {
    return BatchStatus(
      batchIndex: batchIndex,
      phase: phase ?? this.phase,
      message: message ?? this.message,
      audits: audits ?? this.audits,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// Overall progress of the batch commit operation
class BatchCommitProgress {
  final int totalItems;
  final int totalBatches;
  final int currentBatchIndex;
  final List<BatchStatus> batchStatuses;
  final bool isComplete;
  final bool hasFailed;
  final String? failureMessage;

  BatchCommitProgress({
    required this.totalItems,
    required this.totalBatches,
    required this.currentBatchIndex,
    required this.batchStatuses,
    this.isComplete = false,
    this.hasFailed = false,
    this.failureMessage,
  });

  int get completedBatches => 
      batchStatuses.where((b) => b.isCompleted).length;
  
  int get completedItems {
    int count = 0;
    for (var status in batchStatuses) {
      if (status.isCompleted && status.batchIndex < batchStatuses.length) {
        // Each completed batch had batchSize items (except possibly last)
        count += _getItemCountForBatch(status.batchIndex);
      }
    }
    return count;
  }

  int _getItemCountForBatch(int batchIndex) {
    const batchSize = 5000;
    if (batchIndex < totalBatches - 1) {
      return batchSize;
    }
    // Last batch may have fewer items
    return totalItems - (batchSize * (totalBatches - 1));
  }

  double get overallProgress {
    if (totalBatches == 0) return 0;
    return completedBatches / totalBatches;
  }

  BatchStatus? get currentBatch {
    if (currentBatchIndex < 0 || currentBatchIndex >= batchStatuses.length) {
      return null;
    }
    return batchStatuses[currentBatchIndex];
  }

  BatchCommitProgress copyWith({
    int? currentBatchIndex,
    List<BatchStatus>? batchStatuses,
    bool? isComplete,
    bool? hasFailed,
    String? failureMessage,
  }) {
    return BatchCommitProgress(
      totalItems: totalItems,
      totalBatches: totalBatches,
      currentBatchIndex: currentBatchIndex ?? this.currentBatchIndex,
      batchStatuses: batchStatuses ?? this.batchStatuses,
      isComplete: isComplete ?? this.isComplete,
      hasFailed: hasFailed ?? this.hasFailed,
      failureMessage: failureMessage ?? this.failureMessage,
    );
  }
}
