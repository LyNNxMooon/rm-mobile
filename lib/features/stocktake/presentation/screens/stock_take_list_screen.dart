import 'package:flutter/cupertino.dart'
    show CupertinoActivityIndicator;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:rmstock_scanner/entities/vos/counted_stock_vo.dart';
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
  void showErrorDialog(BuildContext context, {required String message}) {
    showDialog(
      context: context,
      builder: (context) {
        return StocktakeCommitErrorDialog(message: message);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton:
          BlocListener<CommittingStocktakeBloc, CommitingStocktakeStates>(
            listener: (context, state) {
              if (state is LoadingToCommitStocktake) {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => const LoadingStocktakeDialog(),
                );
              }

              if (state is ErrorCommitingStocktake) {
                context.navigateBack();
                showErrorDialog(context, message: state.message);
              }

              if (state is CommittedStocktake) {
                context.navigateBack();
                showTopSnackBar(
                  Overlay.of(context),
                  CustomSnackBar.success(message: state.message),
                );
                context.read<FetchingStocktakeListBloc>().add(
                  FetchStocktakeListEvent(),
                );
              }
            },
            child: FloatingActionButton.extended(
              onPressed: () async {
                final unSyncedList = await LocalDbDAO.instance
                    .getUnsyncedStocks(AppGlobals.instance.shopfront ?? "");

                if (unSyncedList.isNotEmpty) {
                  if (context.mounted) {
                    context.read<CommittingStocktakeBloc>().add(
                      CommittingStocktakeEvent(),
                    );
                  }
                } else {
                  if (context.mounted) {
                    showTopSnackBar(
                      Overlay.of(context),
                      const CustomSnackBar.info(
                        message: "No unsynced stocks found.",
                      ),
                    );
                  }
                }
              },
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
          ),
      backgroundColor: kBgColor,
      body: SafeArea(
        child: Column(
          children: [
            const StocktakeListAppBar(),
            const SizedBox(height: 8),
            StocktakeSearchAndFilterBar(
              onChanged: (value) {},
              onFilterTap: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return const FilterDialog();
                  },
                );
              },
            ),
            const SizedBox(height: 10),

            // Expanded List to take remaining space
            Expanded(child: itemsList()),
          ],
        ),
      ),
    );
  }

  Widget itemsList() {
    return BlocBuilder<FetchingStocktakeListBloc, StocktakeListStates>(
      builder: (context, state) {
        if (state is LoadingStocktakeList) {
          return const Center(child: CupertinoActivityIndicator());
        } else if (state is StocktakeListError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                state.message,
                textAlign: TextAlign.center,
                style: getSmartTitle(color: kErrorColor, fontSize: 16),
              ),
            ),
          );
        } else if (state is StocktakeListLoaded) {
          if (state.stocktakeList.isEmpty) {
            return Center(
              child: SingleChildScrollView(
                child: Column(
                  //mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 100,
                      height: 100,
                      child: Image.asset(
                        "assets/images/box.png",
                        fit: BoxFit.fill,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "Your Stocktake list is empty!",
                      style: getSmartTitle(color: kPrimaryColor, fontSize: 16),
                    ),
                  ],
                ),
              ),
            );
          } else {
            return AnimationLimiter(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(
                  15,
                  0,
                  15,
                  80,
                ), // Bottom padding for FAB
                separatorBuilder: (context, index) => const SizedBox(height: 7),
                physics: const BouncingScrollPhysics(),
                itemCount: state.stocktakeList.length,
                itemBuilder: (context, index) {
                  return itemTile(state.stocktakeList[index], index);
                },
              ),
            );
          }
        } else {
          return const SizedBox();
        }
      },
    );
  }

  Widget itemTile(CountedStockVO stock, int index) {
    return AnimationConfiguration.staggeredList(
      position: index,
      duration: const Duration(milliseconds: 500),
      child: ScaleAnimation(
        child: FadeInAnimation(
          child: Slidable(
            key: ValueKey(stock.stockID),
            endActionPane: ActionPane(
              motion: const DrawerMotion(),
              dismissible: DismissiblePane(
                onDismissed: () {
                  LocalDbDAO.instance.deleteStocktake(
                    stock.stockID,
                    AppGlobals.instance.shopfront ?? "",
                  );
                  context.read<FetchingStocktakeListBloc>().add(
                    FetchStocktakeListEvent(),
                  );
                },
              ),
              children: [
                SlidableAction(
                  onPressed: (context) {
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
              decoration: BoxDecoration(
                color: kSecondaryColor,
                borderRadius: const BorderRadius.all(Radius.circular(10)),
                boxShadow: [
                  BoxShadow(
                    color: kThirdColor.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                    spreadRadius: 0,
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Responsive Text Column
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          Icons.cloud_done_outlined,
                          size: 18,
                          color: kGreyColor,
                        ),
                        const SizedBox(width: 15),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              stock.description,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: getSmartTitle(
                                color: kThirdColor,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              stock.barcode,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: kPrimaryColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 10),

                  // Quantity Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: kPrimaryColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      stock.quantity.toString(),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: kPrimaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
