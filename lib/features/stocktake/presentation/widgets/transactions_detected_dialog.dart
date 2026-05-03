import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rmmobile/features/stocktake/domain/entities/stocktake_audit_entities.dart';
import 'package:rmmobile/features/stocktake/presentation/BLoC/stocktake_bloc.dart';
import 'package:rmmobile/features/stocktake/presentation/BLoC/batch_commit_bloc.dart';
import 'package:rmmobile/features/stocktake/presentation/BLoC/stocktake_events.dart';
import 'package:rmmobile/features/stocktake/presentation/utils/transaction_type_helper.dart';
import 'package:rmmobile/constants/colors.dart';
import 'package:rmmobile/constants/standard_dialog.dart';
import 'package:rmmobile/constants/theme_colors.dart';

/// Dialog to display detected transactions during stocktake commit.
/// Allows user to select which items to apply adjustments for.
class TransactionsDetectedDialog extends StatefulWidget {
  final List<AuditWithStockVO> rows;
  final bool isBatchMode;
  final int? currentBatchNumber;
  final int? totalBatches;

  const TransactionsDetectedDialog({
    super.key,
    required this.rows,
    this.isBatchMode = false,
    this.currentBatchNumber,
    this.totalBatches,
  });

  @override
  State<TransactionsDetectedDialog> createState() =>
      _TransactionsDetectedDialogState();
}

class _TransactionsDetectedDialogState
    extends State<TransactionsDetectedDialog> {
  late Set<int> _selectedIndices;

  @override
  void initState() {
    super.initState();
    // Select all items by default
    _selectedIndices = Set.from(List.generate(widget.rows.length, (i) => i));
  }

  bool get _allSelected => _selectedIndices.length == widget.rows.length;
  bool get _noneSelected => _selectedIndices.isEmpty;

  void _toggleSelectAll() {
    setState(() {
      if (_allSelected) {
        _selectedIndices.clear();
      } else {
        _selectedIndices =
            Set.from(List.generate(widget.rows.length, (i) => i));
      }
    });
  }

  void _toggleItem(int index) {
    setState(() {
      if (_selectedIndices.contains(index)) {
        _selectedIndices.remove(index);
      } else {
        _selectedIndices.add(index);
      }
    });
  }

  List<AuditWithStockVO> get _selectedRows =>
      _selectedIndices.map((i) => widget.rows[i]).toList();

  void _onAdjustAndCommit() {
    if (widget.isBatchMode) {
      context.read<BatchCommitBloc>().add(
            ResolveBatchAuditsWithSelectionEvent(
              selectedAudits: _selectedRows,
            ),
          );
    } else {
      context.read<SendingFinalStocktakeBloc>().add(
            SendingFinalStocktakeEvent(_selectedRows),
          );
    }
    Navigator.pop(context);
  }

  void _onIgnoreAndCommit() {
    if (widget.isBatchMode) {
      context.read<BatchCommitBloc>().add(
            ResolveBatchAuditsEvent(applyAdjustments: false),
          );
    } else {
      context.read<SendingFinalStocktakeBloc>().add(
            SendingFinalStocktakeEvent([]),
          );
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final bool isDark = colors.isDark;
    final screenSize = MediaQuery.of(context).size;

    // Calculate dialog dimensions - almost full screen height, wider but not edge-to-edge
    final double dialogWidth = screenSize.width * 0.92;
    //final double maxDialogWidth = 600.0;
    final double dialogHeight = screenSize.height * 0.95;

    final subtitle = widget.isBatchMode &&
            widget.currentBatchNumber != null &&
            widget.totalBatches != null
        ? "Batch ${widget.currentBatchNumber} of ${widget.totalBatches}"
        : null;

    return StandardDialog(
      title: "Transactions Detected",
      subtitle: subtitle,
      colors: colors,
      isDark: isDark,
      maxWidth: dialogWidth,
      content: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: dialogHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                widget.isBatchMode
                    ? "The following items in batch ${widget.currentBatchNumber} were modified recently. Select items to apply adjustments:"
                    : "The following items were modified recently. Select items to apply adjustments:",
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white70 : colors.onSurfaceMuted,
                ),
              ),
            ),
            _buildSelectAllRow(colors, isDark),
            const SizedBox(height: 8),
            Flexible(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isDark ? Colors.white24 : colors.divider,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: widget.rows.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1, indent: 60),
                  itemBuilder: (context, i) =>
                      _buildAuditTile(widget.rows[i], i, colors, isDark),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        DialogActionsRow(
          actions: [
            DialogTextAction(
              label: _noneSelected
                  ? "Adjust & Commit"
                  : "Adjust (${_selectedIndices.length}) & Commit",
              style: DialogActionStyle.outline,
              onPressed: _onAdjustAndCommit,
            ),
            DialogTextAction(
              label: "Ignore & Commit",
              style: DialogActionStyle.primary,
              onPressed: _onIgnoreAndCommit,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSelectAllRow(AppThemeColors colors, bool isDark) {
    return Material(
      color: isDark
          ? colors.surface.withOpacity(0.5)
          : kPrimaryColor.withOpacity(0.05),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: _toggleSelectAll,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: _allSelected,
                  tristate: true,
                  onChanged: (_) => _toggleSelectAll(),
                  activeColor: kPrimaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                _allSelected ? "Deselect All" : "Select All",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: isDark ? Colors.white : colors.onSurface,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: kPrimaryColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "${_selectedIndices.length} / ${widget.rows.length}",
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: kPrimaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAuditTile(
      AuditWithStockVO row, int index, AppThemeColors colors, bool isDark) {
    final s = row.stock;
    final a = row.audit;
    final timeStr = _formatAuditTime(a.auditDate);
    final isSelected = _selectedIndices.contains(index);

    return InkWell(
      onTap: () => _toggleItem(index),
      child: Container(
        color: isSelected
            ? kPrimaryColor.withOpacity(isDark ? 0.15 : 0.08)
            : null,
        child: ListTile(
          dense: true,
          leading: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: isSelected,
                  onChanged: (_) => _toggleItem(index),
                  activeColor: kPrimaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: kPrimaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  TransactionTypeHelper.getIcon(a.tranType),
                  color: kPrimaryColor,
                  size: 20,
                ),
              ),
            ],
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                s?.description ?? "Stock #${a.stockId}",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: isDark ? Colors.white : null,
                ),
              ),
              if (s?.barcode != null)
                Text(
                  s!.barcode,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: kPrimaryColor.withOpacity(0.8),
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              "${TransactionTypeHelper.translate(a.tranType)} on $timeStr",
              style: TextStyle(
                color: isDark ? Colors.white70 : colors.onSurfaceMuted,
                fontSize: 11,
              ),
            ),
          ),
          trailing: Text(
            (a.movement > 0 ? "+" : "") +
                (a.movement % 1 == 0
                    ? a.movement.toInt().toString()
                    : a.movement.toString()),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: a.movement < 0 ? kErrorColor : Colors.green,
            ),
          ),
        ),
      ),
    );
  }

  String _formatAuditTime(dynamic auditDate) {
    try {
      final dt = DateTime.parse(auditDate.toString());
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      final datePart = "${dt.day} ${months[dt.month - 1]}";
      final timePart =
          "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";

      return "$datePart, $timePart";
    } catch (_) {
      return auditDate.toString();
    }
  }
}
