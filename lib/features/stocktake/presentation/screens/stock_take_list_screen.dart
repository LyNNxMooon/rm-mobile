import 'dart:async';

import 'package:alert_info/alert_info.dart';
import 'package:flutter/cupertino.dart' show CupertinoActivityIndicator;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:rmmobile/entities/vos/counted_stock_vo.dart';
import 'package:rmmobile/features/stocktake/presentation/BLoC/stocktake_bloc.dart';
import 'package:rmmobile/features/stocktake/presentation/BLoC/batch_commit_bloc.dart';
import 'package:rmmobile/features/stocktake/presentation/widgets/edit_qty_dialog.dart';
import 'package:rmmobile/features/stocktake/presentation/widgets/empty_stock_state_widget.dart';
import 'package:rmmobile/features/stocktake/presentation/widgets/batch_commit_progress_widget.dart';
import 'package:rmmobile/features/stocktake/domain/entities/stocktake_audit_entities.dart';
import 'package:rmmobile/features/stocktake/presentation/utils/transaction_type_helper.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

import '../../../../constants/colors.dart';
import '../../../../constants/theme_colors.dart';
import '../../../../constants/txt_styles.dart';
import '../../../../utils/dialog_size_utils.dart';
import '../BLoC/stocktake_events.dart';
import '../BLoC/stocktake_states.dart';
import '../widgets/filter_dialog.dart';
//import '../widgets/loading_stocktake_dialog.dart';
import '../widgets/stocktake_commit_error_dialog.dart';
import '../widgets/stocktake_list_app_bar.dart';
import '../widgets/stocktake_search_and_filter_bar.dart';
import '../widgets/stocktake_success_dialog.dart';
import '../widgets/stocktake_trial_limit_info.dart';
import '../widgets/stocktake_validation_info.dart';

class Debouncer {
  final int milliseconds;
  Timer? _timer;
  Debouncer({required this.milliseconds});

  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }

  void dispose() => _timer?.cancel();
}

class StockTakeListScreen extends StatefulWidget {
  const StockTakeListScreen({super.key});

  @override
  State<StockTakeListScreen> createState() => _StockTakeListScreenState();
}

class _StockTakeListScreenState extends State<StockTakeListScreen> {
  final Debouncer _debouncer = Debouncer(milliseconds: 500);
  String _searchQuery = "";

  Future<void> _handleSendToRM() async {
    if (mounted) {
      // Use batch commit for processing stocktake in chunks of 5000
      context.read<BatchCommitBloc>().add(StartBatchCommitEvent());
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (_) => StocktakeCommitErrorDialog(message: message),
    );
  }

  @override
  void initState() {
    super.initState();
    context.read<FetchingStocktakeListBloc>().add(
      FetchStocktakeListEvent(reset: true),
    );
    context.read<StocktakeLimitBloc>().add(FetchStocktakeLimitEvent());
  }

  @override
  void dispose() {
    _debouncer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return BlocListener<StocktakeDeleteBloc, StocktakeDeleteStates>(
      listener: (context, state) {
        if (state is StocktakeDeleted) {
          showTopSnackBar(
            Overlay.of(context),
            CustomSnackBar.success(message: state.message),
          );
          context.read<FetchingStocktakeListBloc>().add(
            FetchStocktakeListEvent(reset: true, query: _searchQuery),
          );
        } else if (state is StocktakeDeleteError) {
          showTopSnackBar(
            Overlay.of(context),
            CustomSnackBar.error(message: state.message),
          );
        }
      },
      child: Scaffold(
        backgroundColor: colors.bg,
        floatingActionButton: _buildSubmitFAB(),
        body: SafeArea(
          child: Column(
            children: [
              const StocktakeListAppBar(),
              const StocktakeValidationInfo(),
              const StocktakeTrialLimitInfo(),
              const BatchCommitProgressWidget(),
              const SizedBox(height: 6),
              StocktakeSearchAndFilterBar(
                onChanged: (value) {
                  _searchQuery = value;

                  _debouncer.run(() {
                    context.read<FetchingStocktakeListBloc>().add(
                      FetchStocktakeListEvent(
                        reset: true, // reset paging for new search
                        query: _searchQuery,
                      ),
                    );
                  });
                },
                onFilterTap: () => showDialog(
                  context: context,
                  builder: (_) => const FilterDialog(),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(child: _buildItemsList()),
              stockCountUpdateListener(),
            ],
          ),
        ),
      ),
    );
  }

  //Stock count update listener
  Widget stockCountUpdateListener() {
    final colors = context.appColors;
    return BlocListener<StockCountUpdateBloc, StockCountUpdateStates>(
      listener: (context, state) {
        if (state is StockCountUpdated) {
          AlertInfo.show(
            context: context,

            text: state.message,

            typeInfo: TypeInfo.success,

            backgroundColor: colors.surface,

            iconColor: kPrimaryColor,

            textColor: colors.onSurface,
            padding: 70,
            position: MessagePosition.top,
          );
        }

        if (state is StockCountUpdateError) {
          showTopSnackBar(
            Overlay.of(context),

            CustomSnackBar.error(message: state.message),
          );
        }
      },
      child: const SizedBox(),
    );
  }

  Widget finalStocktakeLoading() {
    final colors = context.appColors;
    final bool isDark = colors.isDark;
    return BlocConsumer<SendingFinalStocktakeBloc, SendingFinalStocktakeStates>(
      listener: (context, state) {
        if (state is ErrorSendingStocktake) {
          context.read<StocktakeLimitBloc>().add(FetchStocktakeLimitEvent());
          _showError(state.message);
        }

        if (state is SentStocktakeToRM) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => StocktakeSuccessDialog(
              message: state.message,
              onOkayPressed: () {
                Navigator.of(context).pop();

                context.read<FetchingStocktakeListBloc>().add(
                  FetchStocktakeListEvent(),
                );
                context.read<FetchingStocktakeListBloc>().add(
                  FetchStocktakeListEvent(),
                );
                context.read<StocktakeLimitBloc>().add(
                  FetchStocktakeLimitEvent(),
                );
              },
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is LoadingToSendStocktake) {
          return Container(
            margin: const EdgeInsets.only(
              left: 15,
              right: 15,
              top: 4,
              bottom: 4,
            ),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? colors.surfaceAlt : colors.surface,
              borderRadius: BorderRadius.circular(8),
              border: isDark
                  ? Border.all(color: Colors.white30, width: 1)
                  : null,
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Sending final Stocktake...",
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      "${(0.5 * 100).toStringAsFixed(0)}%",
                      style: TextStyle(
                        fontSize: 14,
                        color: kPrimaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: 0.5,
                  backgroundColor: colors.divider,
                  valueColor: AlwaysStoppedAnimation<Color>(kPrimaryColor),
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                ),
                const SizedBox(height: 5),
                Text(
                  "This may take a few seconds",
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.onSurfaceMuted,
                  ),
                ),
              ],
            ),
          );
        } else {
          return SizedBox.shrink();
        }
      },
    );
  }

  Widget _buildSubmitFAB() {
    final colors = context.appColors;
    
    return BlocListener<BatchCommitBloc, BatchCommitState>(
      listener: (context, state) {
        if (state is BatchCommitAwaitingAuditDecision) {
          // Show audit decision dialog for current batch
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => _buildBatchValidationDialog(state),
          );
        } else if (state is BatchCommitEmpty) {
          _showError("No unsynced stocks found.");
        } else if (state is BatchCommitFailed) {
          context.read<StocktakeLimitBloc>().add(FetchStocktakeLimitEvent());
          _showError(state.message);
        } else if (state is BatchCommitCompleted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => StocktakeSuccessDialog(
              message: "Stocktake data sent to RetailManager! Please navigate to Stock Management -> Stocktake -> Run Discrepancy Report and Commit the Stocktake.",
              onOkayPressed: () {
                Navigator.of(context).pop();
                context.read<FetchingStocktakeListBloc>().add(
                  FetchStocktakeListEvent(reset: true),
                );
                context.read<StocktakeLimitBloc>().add(
                  FetchStocktakeLimitEvent(),
                );
                // Reset batch commit bloc state
                context.read<BatchCommitBloc>().add(CancelBatchCommitEvent());
              },
            ),
          );
        }
      },
      child: FloatingActionButton.extended(
        onPressed: _handleSendToRM,
        elevation: 4,
        backgroundColor: kPrimaryColor,
        label: Text(
          "Send Stocktake to RM",
          style: TextStyle(
            color: colors.onHero,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildItemsList() {
    return BlocBuilder<FetchingStocktakeListBloc, StocktakeListStates>(
      builder: (context, state) {
        if (state is LoadingStocktakeList) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 85),
              child: CupertinoActivityIndicator(),
            ),
          );
        }

        if (state is StocktakeListError) {
          return Center(
            child: Text(
              state.message,
              style: getSmartTitle(color: kErrorColor, fontSize: 16),
            ),
          );
        }

        if (state is StocktakeListLoaded) {
          if (state.stocktakeList.isEmpty) return _buildEmptyState();

          return AnimationLimiter(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(15, 0, 15, 80),
              separatorBuilder: (_, _) => const SizedBox(height: 7),
              physics: const BouncingScrollPhysics(),
              itemCount: state.stocktakeList.length,
              itemBuilder: (context, index) =>
                  _itemTile(state.stocktakeList[index], index),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            EmptyStockState(
              message: "Your stocktake list is empty",
              onRetry: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _itemTile(CountedStockVO stock, int index) {
    final colors = context.appColors;
    final bool isDark = colors.isDark;
    return AnimationConfiguration.staggeredList(
      position: index,
      duration: const Duration(milliseconds: 500),
      child: ScaleAnimation(
        child: FadeInAnimation(
          child: Slidable(
            key: ValueKey(stock.stockID),
            endActionPane: ActionPane(
              motion: const DrawerMotion(),
              children: [
                SlidableAction(
                  onPressed: (_) {
                    context.read<StocktakeDeleteBloc>().add(
                      DeleteStocktakeEvent(stock.stockID),
                    );
                  },
                  backgroundColor: kErrorColor,
                  foregroundColor: colors.onHero,
                  icon: Icons.delete,
                  label: 'Delete',
                  borderRadius: const BorderRadius.horizontal(
                    right: Radius.circular(10),
                  ),
                ),
              ],
            ),
            child: InkWell(
              onTap: () {
                context.read<StockDetailsBloc>().add(
                  FetchStockDetailsByID(
                    stockId: stock.stockID,
                    qty: stock.quantity,
                  ),
                );

                showDialog(
                  context: context,
                  builder: (context) => const StockDetailsDialog(),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isDark ? colors.surfaceAlt : colors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: isDark
                      ? Border.all(color: Colors.white30, width: 1)
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: colors.cardShadow,
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.cloud_done_outlined,
                      size: 18,
                      color: isDark ? Colors.white70 : colors.onSurfaceMuted,
                    ),
                    const SizedBox(width: 15),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            stock.description,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: getSmartTitle(
                              color: isDark ? Colors.white : colors.onSurface,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2), // Spacing
                          Wrap(
                            // Wrap handles overflow better than Row here
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              Text(
                                stock.barcode,
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: kPrimaryColor,
                                ),
                              ),
                              // Vertical Divider Visual
                              Text(
                                "|",
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white54
                                      : colors.onSurfaceMuted,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                "In-Stock: ${stock.inStock}",
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: kPrimaryColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    _buildQtyBadge(stock.quantity),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQtyBadge(num qty) {
    String formattedQty;

    if (qty % 1 == 0) {
      // It's an integer (e.g. 5.0 -> "5")
      formattedQty = qty.toInt().toString();
    } else {
      // It's a decimal. Limit to 4 decimal places and remove trailing zeros.
      // e.g. 5.123456 -> "5.1235"
      // e.g. 5.5000 -> "5.5"
      formattedQty = qty.toStringAsFixed(4);
      // Remove trailing zeros and unnecessary decimal point
      formattedQty = formattedQty.replaceAll(RegExp(r"([.]*0+)(?!.*\d)"), "");
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: kPrimaryColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        "Counted: $formattedQty",
        style: const TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w900,
          color: kPrimaryColor,
        ),
      ),
    );
  }

  Widget _buildValidationDialog(StocktakeValidationHasAudits state) {
    final colors = context.appColors;
    final bool isDark = colors.isDark;
    final double safeMaxHeight = MediaQuery.of(context).size.height * 0.7;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: isDark
            ? const BorderSide(color: Colors.white30, width: 1)
            : BorderSide.none,
      ),
      backgroundColor: isDark ? colors.surfaceAlt : colors.surface,
      titlePadding: EdgeInsets.zero,
      insetPadding: dialogInsetPadding(context),
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
      title: _buildDialogHeader(),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                "The following items were modified recently. How would you like to proceed?",
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white70 : colors.onSurfaceMuted,
                ),
              ),
            ),

            Flexible(
              child: Container(
                constraints: BoxConstraints(maxHeight: safeMaxHeight),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isDark ? Colors.white24 : colors.divider,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: state.rows.length,
                  separatorBuilder: (_, _) =>
                      const Divider(height: 1, indent: 60),
                  itemBuilder: (context, i) => _buildAuditTile(state.rows[i]),
                ),
              ),
            ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(15, 0, 15, 20),
      actions: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  context.read<SendingFinalStocktakeBloc>().add(
                    SendingFinalStocktakeEvent(state.rows),
                  );
                  Navigator.pop(context);
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(color: kPrimaryColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  "Adjust & Commit",
                  style: TextStyle(
                    color: kPrimaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  context.read<SendingFinalStocktakeBloc>().add(
                    SendingFinalStocktakeEvent([]),
                  );
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  "Ignore & Commit",
                  style: TextStyle(
                    color: colors.onHero,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Validation dialog specifically for batch commit mode
  Widget _buildBatchValidationDialog(BatchCommitAwaitingAuditDecision state) {
    final colors = context.appColors;
    final bool isDark = colors.isDark;
    final double safeMaxHeight = MediaQuery.of(context).size.height * 0.7;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: isDark
            ? const BorderSide(color: Colors.white30, width: 1)
            : BorderSide.none,
      ),
      backgroundColor: isDark ? colors.surfaceAlt : colors.surface,
      titlePadding: EdgeInsets.zero,
      insetPadding: dialogInsetPadding(context),
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
      title: _buildBatchDialogHeader(state),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                "The following items in batch ${state.currentBatchNumber} were modified recently. How would you like to proceed?",
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white70 : colors.onSurfaceMuted,
                ),
              ),
            ),

            Flexible(
              child: Container(
                constraints: BoxConstraints(maxHeight: safeMaxHeight),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isDark ? Colors.white24 : colors.divider,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: state.audits.length,
                  separatorBuilder: (_, _) =>
                      const Divider(height: 1, indent: 60),
                  itemBuilder: (context, i) => _buildAuditTile(state.audits[i]),
                ),
              ),
            ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(15, 0, 15, 20),
      actions: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  // Apply adjustments for this batch
                  context.read<BatchCommitBloc>().add(
                    ResolveBatchAuditsEvent(applyAdjustments: true),
                  );
                  Navigator.pop(context);
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(color: kPrimaryColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  "Adjust & Commit",
                  style: TextStyle(
                    color: kPrimaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  // Ignore adjustments for this batch
                  context.read<BatchCommitBloc>().add(
                    ResolveBatchAuditsEvent(applyAdjustments: false),
                  );
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  "Ignore & Commit",
                  style: TextStyle(
                    color: colors.onHero,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Dialog header for batch commit mode with batch info
  Widget _buildBatchDialogHeader(BatchCommitAwaitingAuditDecision state) {
    final colors = context.appColors;
    final bool isDark = colors.isDark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
      decoration: BoxDecoration(
        color: isDark ? colors.surfaceAlt : const Color(0xFFFFF4E5),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.white24 : Colors.orange.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.orange,
            child: Icon(
              Icons.warning_amber_rounded,
              color: colors.onHero,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Transactions Detected",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF663C00),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "Batch ${state.currentBatchNumber} of ${state.totalBatches}",
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white70 : const Color(0xFF996600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogHeader() {
    final colors = context.appColors;
    final bool isDark = colors.isDark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
      decoration: BoxDecoration(
        color: isDark ? colors.surfaceAlt : const Color(0xFFFFF4E5),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.white24 : Colors.orange.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.orange,
            child: Icon(
              Icons.warning_amber_rounded,
              color: colors.onHero,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Transactions Detected",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF663C00),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuditTile(AuditWithStockVO row) {
    final colors = context.appColors;
    final bool isDark = colors.isDark;
    final s = row.stock;
    final a = row.audit;
    final timeStr = _formatAuditTime(a.auditDate);

    return ListTile(
      dense: true,
      leading: Container(
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
