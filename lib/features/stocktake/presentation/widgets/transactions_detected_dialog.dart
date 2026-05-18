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
import 'package:rmmobile/utils/responsive_utils.dart';

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
    final bool useDesktopNav = context.useDesktopNav;
    final screenSize = MediaQuery.of(context).size;

    // Calculate dialog dimensions - desktop uses fixed width, mobile uses percentage
    final double dialogWidth = useDesktopNav ? 700.0 : screenSize.width * 0.92;
    final double dialogHeight = useDesktopNav ? screenSize.height * 0.85 : screenSize.height * 0.95;
    
    // Desktop-specific sizing
    final double descFontSize = useDesktopNav ? 12.0 : 13.0;
    final double selectAllPaddingH = useDesktopNav ? 10.0 : 12.0;
    final double selectAllPaddingV = useDesktopNav ? 8.0 : 10.0;
    final double checkboxSize = useDesktopNav ? 20.0 : 24.0;
    final double selectAllFontSize = useDesktopNav ? 12.0 : 14.0;
    final double countBadgeFontSize = useDesktopNav ? 11.0 : 12.0;
    final double borderRadius = useDesktopNav ? 8.0 : 12.0;

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
              padding: EdgeInsets.only(bottom: useDesktopNav ? 6 : 8),
              child: Text(
                widget.isBatchMode
                    ? "The following items in batch ${widget.currentBatchNumber} were modified recently. Select items to apply adjustments:"
                    : "The following items were modified recently. Select items to apply adjustments:",
                style: TextStyle(
                  fontSize: descFontSize,
                  color: isDark ? Colors.white70 : colors.onSurfaceMuted,
                ),
              ),
            ),
            _buildSelectAllRow(colors, isDark, useDesktopNav, selectAllPaddingH, selectAllPaddingV, checkboxSize, selectAllFontSize, countBadgeFontSize),
            SizedBox(height: useDesktopNav ? 6 : 8),
            Flexible(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isDark ? Colors.white24 : colors.divider,
                  ),
                  borderRadius: BorderRadius.circular(borderRadius),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: widget.rows.length,
                  separatorBuilder: (context, index) =>
                      Divider(height: 1, indent: useDesktopNav ? 50 : 60),
                  itemBuilder: (context, i) =>
                      _buildAuditTile(widget.rows[i], i, colors, isDark, useDesktopNav),
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

  Widget _buildSelectAllRow(AppThemeColors colors, bool isDark, bool useDesktopNav, double paddingH, double paddingV, double checkboxSize, double fontSize, double badgeFontSize) {
    return Material(
      color: isDark
          ? colors.surface.withOpacity(0.5)
          : kPrimaryColor.withOpacity(0.05),
      borderRadius: BorderRadius.circular(useDesktopNav ? 6 : 8),
      child: InkWell(
        onTap: _toggleSelectAll,
        borderRadius: BorderRadius.circular(useDesktopNav ? 6 : 8),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: paddingH, vertical: paddingV),
          child: Row(
            children: [
              SizedBox(
                width: checkboxSize,
                height: checkboxSize,
                child: Checkbox(
                  value: _allSelected,
                  tristate: true,
                  onChanged: (_) => _toggleSelectAll(),
                  activeColor: kPrimaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(useDesktopNav ? 3 : 4),
                  ),
                ),
              ),
              SizedBox(width: useDesktopNav ? 10 : 12),
              Text(
                _allSelected ? "Deselect All" : "Select All",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: fontSize,
                  color: isDark ? Colors.white : colors.onSurface,
                ),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: useDesktopNav ? 8 : 10, vertical: useDesktopNav ? 3 : 4),
                decoration: BoxDecoration(
                  color: kPrimaryColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(useDesktopNav ? 10 : 12),
                ),
                child: Text(
                  "${_selectedIndices.length} / ${widget.rows.length}",
                  style: TextStyle(
                    fontSize: badgeFontSize,
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
      AuditWithStockVO row, int index, AppThemeColors colors, bool isDark, bool useDesktopNav) {
    final s = row.stock;
    final a = row.audit;
    final timeStr = _formatAuditTime(a.auditDate);
    final isSelected = _selectedIndices.contains(index);
    
    // Desktop sizing
    final double checkboxSize = useDesktopNav ? 20.0 : 24.0;
    final double iconContainerPadding = useDesktopNav ? 6.0 : 8.0;
    final double iconSize = useDesktopNav ? 16.0 : 20.0;
    final double titleFontSize = useDesktopNav ? 12.0 : 13.0;
    final double barcodeFontSize = useDesktopNav ? 10.0 : 11.0;
    final double subtitleFontSize = useDesktopNav ? 10.0 : 11.0;
    final double trailingFontSize = useDesktopNav ? 12.0 : 14.0;

    return InkWell(
      onTap: () => _toggleItem(index),
      child: Container(
        color: isSelected
            ? kPrimaryColor.withOpacity(isDark ? 0.15 : 0.08)
            : null,
        child: ListTile(
          dense: true,
          visualDensity: useDesktopNav ? VisualDensity.compact : null,
          leading: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: checkboxSize,
                height: checkboxSize,
                child: Checkbox(
                  value: isSelected,
                  onChanged: (_) => _toggleItem(index),
                  activeColor: kPrimaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(useDesktopNav ? 3 : 4),
                  ),
                ),
              ),
              SizedBox(width: useDesktopNav ? 6 : 8),
              Container(
                padding: EdgeInsets.all(iconContainerPadding),
                decoration: BoxDecoration(
                  color: kPrimaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(useDesktopNav ? 6 : 8),
                ),
                child: Icon(
                  TransactionTypeHelper.getIcon(a.tranType),
                  color: kPrimaryColor,
                  size: iconSize,
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
                  fontSize: titleFontSize,
                  color: isDark ? Colors.white : null,
                ),
              ),
              if (s?.barcode != null)
                Text(
                  s!.barcode,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: barcodeFontSize,
                    color: kPrimaryColor.withOpacity(0.8),
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          subtitle: Padding(
            padding: EdgeInsets.only(top: useDesktopNav ? 2 : 4),
            child: Text(
              "${TransactionTypeHelper.translate(a.tranType)} on $timeStr",
              style: TextStyle(
                color: isDark ? Colors.white70 : colors.onSurfaceMuted,
                fontSize: subtitleFontSize,
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
              fontSize: trailingFontSize,
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
