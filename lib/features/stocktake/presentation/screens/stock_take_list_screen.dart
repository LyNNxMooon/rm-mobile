import 'package:flutter/cupertino.dart' show CupertinoActivityIndicator;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:rmstock_scanner/entities/vos/counted_stock_vo.dart';
import 'package:rmstock_scanner/features/stocktake/models/stocktake_model.dart';
import 'package:rmstock_scanner/features/stocktake/presentation/BLoC/stocktake_bloc.dart';
import 'package:rmstock_scanner/utils/navigation_extension.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

import '../../../../constants/colors.dart';
import '../../../../constants/txt_styles.dart';
import '../../../../local_db/local_db_dao.dart';
import '../../../../utils/global_var_utils.dart';
import '../BLoC/stocktake_events.dart';
import '../BLoC/stocktake_states.dart';
import '../widgets/filter_dialog.dart';
import '../widgets/loading_stocktake_dialog.dart';
import '../widgets/stocktake_commit_error_dialog.dart';
import '../widgets/stocktake_list_app_bar.dart';
import '../widgets/stocktake_search_and_filter_bar.dart';

class StockTakeListScreen extends StatefulWidget {
  const StockTakeListScreen({super.key});

  @override
  State<StockTakeListScreen> createState() => _StockTakeListScreenState();
}

class _StockTakeListScreenState extends State<StockTakeListScreen> {
  Future<void> _handleSendToRM() async {
    final unSyncedList = await LocalDbDAO.instance.getUnsyncedStocks(
      AppGlobals.instance.shopfront ?? "",
    );

    if (unSyncedList.isNotEmpty) {
      if (mounted) {
        context.read<CommittingStocktakeBloc>().add(CommittingStocktakeEvent());
      }
    } else {
      if (mounted) {
        showTopSnackBar(
          Overlay.of(context),
          const CustomSnackBar.error(message: "No unsynced stocks found."),
        );
      }
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (_) => StocktakeCommitErrorDialog(message: message),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgColor,
      floatingActionButton: _buildSubmitFAB(),
      body: SafeArea(
        child: Column(
          children: [
            const StocktakeListAppBar(),
            const SizedBox(height: 5),
            StocktakeSearchAndFilterBar(
              onChanged: (value) {},
              onFilterTap: () => showDialog(
                context: context,
                builder: (_) => const FilterDialog(),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(child: _buildItemsList()),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitFAB() {
    return MultiBlocListener(
      listeners: [
        BlocListener<CommittingStocktakeBloc, CommitingStocktakeStates>(
          listener: (context, state) {
            if (state is LoadingToCommitStocktake) {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => const LoadingStocktakeDialog(),
              );
            } else if (state is ErrorCommitingStocktake) {
              context.navigateBack();
              _showError(state.message);
            } else if (state is CommittedStocktake) {
              context.navigateBack();
              showTopSnackBar(
                Overlay.of(context),
                CustomSnackBar.info(message: state.message),
              );
              // Trigger Validation after successful initial commit
              context.read<StocktakeValidationBloc>().add(
                StartStocktakeValidationEvent(),
              );
            }
          },
        ),
        BlocListener<StocktakeValidationBloc, StocktakeValidationState>(
          listener: (context, state) {
            if (state is StocktakeValidationError) {
              _showError(state.message);
            } else if (state is StocktakeValidationHasAudits) {
              showDialog(
                context: context,
                barrierDismissible: false,

                builder: (_) => _buildValidationDialog(state),
              );
            } else if (state is StocktakeValidationClear) {
              // showTopSnackBar(
              //   Overlay.of(context),
              //   const CustomSnackBar.success(
              //     message: "Stocktake fully synced!",
              //   ),
              // );
            }
          },
        ),
      ],
      child: FloatingActionButton.extended(
        onPressed: _handleSendToRM,
        elevation: 4,
        backgroundColor: kPrimaryColor,
        label: const Text(
          "Send Stocktake to RM",
          style: TextStyle(
            color: kSecondaryColor,
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
          return const Center(child: CupertinoActivityIndicator());
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 100,
            height: 100,
            child: Image.asset("assets/images/box.png", fit: BoxFit.fill),
          ),
          const SizedBox(height: 20),
          Text(
            "Your Stocktake list is empty!",
            style: getSmartTitle(color: kPrimaryColor, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _itemTile(CountedStockVO stock, int index) {
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
                    LocalDbDAO.instance.deleteStocktake(
                      stock.stockID,
                      AppGlobals.instance.shopfront ?? "",
                    );
                    context.read<FetchingStocktakeListBloc>().add(
                      FetchStocktakeListEvent(),
                    );
                  },
                  backgroundColor: kErrorColor,
                  foregroundColor: kSecondaryColor,
                  icon: Icons.delete,
                  label: 'Delete',
                  borderRadius: const BorderRadius.horizontal(
                    right: Radius.circular(10),
                  ),
                ),
              ],
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: kSecondaryColor,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: kThirdColor.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(Icons.cloud_done_outlined, size: 18, color: kGreyColor),
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
                            color: kThirdColor,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          stock.barcode,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: kPrimaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  _buildQtyBadge(stock.quantity.toString()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQtyBadge(String qty) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: kPrimaryColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        qty,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w900,
          color: kPrimaryColor,
        ),
      ),
    );
  }

Widget _buildValidationDialog(StocktakeValidationHasAudits state) {
  
  final double safeMaxHeight = MediaQuery.of(context).size.height * 0.7;

  return AlertDialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    backgroundColor: kSecondaryColor,
    titlePadding: EdgeInsets.zero,
    insetPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 24),
    contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
    title: _buildDialogHeader(),
    content: SizedBox(
      width: double.maxFinite,
      child: Column(
        mainAxisSize: MainAxisSize.min, 
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text(
              "The following items were modified recently. How would you like to proceed?",
              style: TextStyle(fontSize: 13, color: kGreyColor),
            ),
          ),
          
   
          Flexible(
            child: Container(
    
              constraints: BoxConstraints(maxHeight: safeMaxHeight),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade200),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListView.separated(
                shrinkWrap: true, 
                itemCount: state.rows.length,
                separatorBuilder: (_, _) => const Divider(height: 1, indent: 60),
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
                Navigator.pop(context);
        
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: BorderSide(color: kPrimaryColor),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(
                "Adjust & Commit",
                style: TextStyle(color: kPrimaryColor, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
            
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(
                "Ignore & Commit",
                style: TextStyle(color: kSecondaryColor, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    ],
  );
}

  Widget _buildDialogHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
      decoration: const BoxDecoration(
        color: Color(0xFFFFF4E5),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Colors.orange,
            child: Icon(Icons.warning_amber_rounded, color: kSecondaryColor),
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
                    color: Color(0xFF663C00),
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
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
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
          style: TextStyle(color: kGreyColor, fontSize: 11),
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
