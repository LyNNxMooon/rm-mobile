import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rmmobile/features/home_page/presentation/BLoC/home_screen_events.dart';
import 'package:rmmobile/features/stock_lookup/presentation/BLoC/stock_lookup_bloc.dart';
import 'package:rmmobile/features/stock_lookup/presentation/BLoC/stock_lookup_events.dart';
import 'package:rmmobile/features/stock_lookup/presentation/BLoC/stock_lookup_states.dart';
import 'package:rmmobile/features/stock_lookup/presentation/screens/pending_stock_updates_screen.dart';
import 'package:rmmobile/utils/navigation_extension.dart';

import '../../../../constants/colors.dart';
//import '../../../../constants/theme_colors.dart';
import '../../../home_page/presentation/BLoC/home_screen_bloc.dart';
import '../../../home_page/presentation/BLoC/home_screen_states.dart';

class SyncInfoWidget extends StatelessWidget {
  const SyncInfoWidget({super.key});

  static bool _skipNextPrompt = false;

  Future<void> _promptSendPendingStockUpdates(BuildContext context) async {
    context.read<PendingStockUpdatesBloc>().add(
      LoadPendingStockUpdatesEvent(showDialog: false),
    );
    final state = await context
        .read<PendingStockUpdatesBloc>()
        .stream
        .firstWhere((state) => state is PendingStockUpdatesLoaded);
    if (state is! PendingStockUpdatesLoaded || !context.mounted) return;
    if (state.updates.isEmpty) return;

    await context.navigateToNext(
      PendingStockUpdatesScreen(
        showSendButton: true,
        onSend: () async {
          _skipNextPrompt = true;
          await _sendPendingUpdates(context);
        },
      ),
    );
  }

  Future<void> _sendPendingUpdates(BuildContext context) async {
    context.read<PendingStockUpdatesBloc>().add(
      SendPendingStockUpdatesEvent(),
    );

    final result = await context
        .read<PendingStockUpdatesBloc>()
        .stream
        .firstWhere(
          (state) =>
              state is PendingStockUpdatesSent ||
              state is PendingStockUpdatesError,
        );

    if (!context.mounted) return;

    if (result is PendingStockUpdatesSent) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message)),
      );
      final loadedState = await context
          .read<PendingStockUpdatesBloc>()
          .stream
          .firstWhere((state) => state is PendingStockUpdatesLoaded);
      if (loadedState is PendingStockUpdatesLoaded &&
          loadedState.updates.isEmpty) {
        await context
            .read<PendingStockUpdatesBloc>()
            .stream
            .firstWhere((state) => state is PendingStockUpdatesSyncReady);
        if (!context.mounted) return;
        await Future<void>.delayed(const Duration(seconds: 2));
        if (context.read<FetchStockBloc>().state is! FetchStockProgress) {
          context.read<FetchStockBloc>().add(StartSyncEvent(ipAddress: ""));
        }
      }
    } else if (result is PendingStockUpdatesError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message)),
      );
    }

    context.read<PendingStockUpdatesBloc>().add(
      LoadPendingStockUpdatesCountEvent(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15.0),
      child: BlocConsumer<FetchStockBloc, FetchStockStates>(
        listener: (context, state) {
          if (state is FetchStockSuccess) {
            final stockState = context.read<StockListBloc>().state;

            if (stockState is StockListLoaded) {
              context.read<StockListBloc>().add(
                FetchFirstPageEvent(
                  query: stockState.currentQuery,
                  filterColumn: stockState.currentFilterCol,
                  sortColumn: stockState.currentSortCol,
                  filters: stockState.activeFilters,
                  shouldToggleSort: false,
                ),
              );
            } else {
              context.read<StockListBloc>().add(
                FetchFirstPageEvent(shouldToggleSort: false),
              );
            }

            context.read<FilterOptionsBloc>().add(LoadFilterOptionsEvent());
            context.read<PendingStockUpdatesBloc>().add(
              LoadPendingStockUpdatesCountEvent(),
            );
            if (_skipNextPrompt) {
              _skipNextPrompt = false;
            }
            _promptSendPendingStockUpdates(context);
          }
        },
        builder: (context, state) {
        //  final colors = context.appColors;
         // final bool isDark = colors.isDark;
          if (state is FetchStockProgress) {
            return Container(
              margin: const EdgeInsets.only(top: 5, bottom: 2),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: kSecondaryColor,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color:kThirdColor.withOpacity(0.05),
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
                      Expanded(
                        child: Text(
                          state.message,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color:  kThirdColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "${(state.percentage * 100).toStringAsFixed(0)}%",
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
                    value: state.percentage,
                    backgroundColor:
                         Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(kPrimaryColor),
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "${state.currentCount} / ${state.totalCount} records",
                    style: TextStyle(
                      fontSize: 12,
                      color:  kGreyColor,
                    ),
                  ),
                ],
              ),
            );
          } else if (state is FetchStockError) {
            //final scheme = Theme.of(context).colorScheme;
            return Container(
              margin: const EdgeInsets.only(top: 5, bottom: 2),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color:  kErrorColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color:  Colors.red.shade200,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: kErrorColor,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      state.message,
                      style: TextStyle(
                        color: kErrorColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            );
          } else if (state is FetchStockSuccess) {
            return Container(
              margin: const EdgeInsets.only(top: 5, bottom: 2),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.green.shade800.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color:  Colors.green.shade200,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle,
                    color:  Colors.green,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      "Stock Database Updated Successfully",
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color:  Colors.green.shade800,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}