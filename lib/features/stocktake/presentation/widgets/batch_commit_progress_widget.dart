import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rmstock_scanner/constants/colors.dart';
import 'package:rmstock_scanner/constants/theme_colors.dart';
import 'package:rmstock_scanner/constants/txt_styles.dart';
import 'package:rmstock_scanner/features/stocktake/domain/entities/batch_commit_entities.dart';
import 'package:rmstock_scanner/features/stocktake/presentation/BLoC/batch_commit_bloc.dart';

/// Widget that displays batch commit progress with green ticks for completed batches
class BatchCommitProgressWidget extends StatelessWidget {
  const BatchCommitProgressWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isDark = colors.isDark;

    return BlocBuilder<BatchCommitBloc, BatchCommitState>(
      builder: (context, state) {
        if (state is BatchCommitPreparing) {
          return _buildPreparingState(context, state, colors, isDark);
        }

        if (state is BatchCommitInProgress) {
          return _buildProgressState(context, state.progress, colors, isDark);
        }

        if (state is BatchCommitAwaitingAuditDecision) {
          return _buildProgressState(context, state.progress, colors, isDark);
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildPreparingState(
    BuildContext context,
    BatchCommitPreparing state,
    AppThemeColors colors,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.only(left: 15, right: 15, top: 4, bottom: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? colors.surfaceAlt : colors.surface,
        borderRadius: BorderRadius.circular(8),
        border: isDark ? Border.all(color: Colors.white30, width: 1) : null,
        boxShadow: [
          BoxShadow(
            color: colors.cardShadow,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Text(
            state.message,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: colors.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressState(
    BuildContext context,
    BatchCommitProgress progress,
    AppThemeColors colors,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.only(left: 15, right: 15, top: 4, bottom: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? colors.surfaceAlt : colors.surface,
        borderRadius: BorderRadius.circular(8),
        border: isDark ? Border.all(color: Colors.white30, width: 1) : null,
        boxShadow: [
          BoxShadow(
            color: colors.cardShadow,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with overall progress
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Batch Commit Progress",
                style: getSmartTitle(
                  fontSize: 14,
                  color: colors.onSurface,
                ),
              ),
              Text(
                "${progress.completedBatches}/${progress.totalBatches} batches",
                style: TextStyle(
                  fontSize: 13,
                  color: kPrimaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Overall progress bar
          LinearProgressIndicator(
            value: progress.overallProgress,
            backgroundColor: colors.divider,
            valueColor: const AlwaysStoppedAnimation<Color>(kPrimaryColor),
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
          const SizedBox(height: 12),

          // Batch status indicators
          _buildBatchIndicators(progress, colors, isDark),

          const SizedBox(height: 8),

          // Current phase description
          if (progress.currentBatch != null)
            Text(
              _getPhaseDescription(progress),
              style: TextStyle(
                fontSize: 12,
                color: colors.onSurfaceMuted,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBatchIndicators(
    BatchCommitProgress progress,
    AppThemeColors colors,
    bool isDark,
  ) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: progress.batchStatuses.map((status) {
        return _buildBatchChip(status, progress.currentBatchIndex, colors, isDark);
      }).toList(),
    );
  }

  Widget _buildBatchChip(
    BatchStatus status,
    int currentBatchIndex,
    AppThemeColors colors,
    bool isDark,
  ) {
    final isActive = status.batchIndex == currentBatchIndex;
    final isCompleted = status.isCompleted;
    final isFailed = status.isFailed;

    Color bgColor;
    Color borderColor;
    Widget icon;

    if (isCompleted) {
      bgColor = Colors.green.withOpacity(0.15);
      borderColor = Colors.green;
      icon = const Icon(Icons.check_circle, color: Colors.green, size: 16);
    } else if (isFailed) {
      bgColor = Colors.red.withOpacity(0.15);
      borderColor = Colors.red;
      icon = const Icon(Icons.error, color: Colors.red, size: 16);
    } else if (isActive) {
      bgColor = kPrimaryColor.withOpacity(0.15);
      borderColor = kPrimaryColor;
      icon = const SizedBox(
        width: 14,
        height: 14,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(kPrimaryColor),
        ),
      );
    } else {
      bgColor = isDark ? Colors.white10 : Colors.grey.shade100;
      borderColor = isDark ? Colors.white24 : Colors.grey.shade300;
      icon = Icon(
        Icons.pending_outlined,
        color: isDark ? Colors.white38 : Colors.grey,
        size: 16,
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          const SizedBox(width: 6),
          Text(
            "Batch ${status.batchIndex + 1}",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isCompleted
                  ? Colors.green
                  : isFailed
                      ? Colors.red
                      : isActive
                          ? kPrimaryColor
                          : colors.onSurfaceMuted,
            ),
          ),
        ],
      ),
    );
  }

  String _getPhaseDescription(BatchCommitProgress progress) {
    final current = progress.currentBatch;
    if (current == null) return "Processing...";

    final batchNum = progress.currentBatchIndex + 1;
    final total = progress.totalBatches;

    switch (current.phase) {
      case BatchPhase.pending:
        return "Waiting to process batch $batchNum...";
      case BatchPhase.initCheck:
        return "Validating batch $batchNum of $total...";
      case BatchPhase.awaitingAuditDecision:
        return "Batch $batchNum has transactions to review";
      case BatchPhase.finalCommit:
        return "Committing batch $batchNum of $total to RetailManager...";
      case BatchPhase.completed:
        return "Batch $batchNum completed successfully!";
      case BatchPhase.failed:
        return "Batch $batchNum failed: ${current.message}";
    }
  }
}
