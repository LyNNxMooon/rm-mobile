import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rmstock_scanner/features/stock_lookup/presentation/BLoC/stock_lookup_bloc.dart';
import 'package:rmstock_scanner/features/stock_lookup/presentation/BLoC/stock_lookup_events.dart';
import 'package:rmstock_scanner/features/stock_lookup/presentation/BLoC/stock_lookup_states.dart';
import 'package:rmstock_scanner/local_db/local_db_dao.dart';

import '../../../../constants/colors.dart';
import '../../../../constants/theme_colors.dart';
import 'pending_stock_updates_tile.dart';
import '../../../home_page/presentation/BLoC/home_screen_bloc.dart';
import '../../../home_page/presentation/BLoC/home_screen_events.dart';
import '../../../home_page/presentation/BLoC/home_screen_states.dart';
import '../../../customer_lookup/presentation/BLoC/customer_lookup_bloc.dart';
import '../../../customer_lookup/presentation/BLoC/customer_lookup_events.dart';

class SyncInfoWidget extends StatelessWidget {
  const SyncInfoWidget({super.key});

  Future<void> _promptSendPendingStockUpdates(BuildContext context) async {
    final shopfront =
        (await LocalDbDAO.instance.getShopfrontName() ?? '').trim();
    if (shopfront.isEmpty) return;

    final pendingCount =
        await LocalDbDAO.instance.getPendingStockUpdatesCount(shopfront);
    if (pendingCount <= 0) return;

    final pendingUpdates = await LocalDbDAO.instance.getPendingStockUpdates(
      shopfront,
    );
    if (pendingUpdates.isEmpty || !context.mounted) return;

    await showPendingStockUpdatesDialog(
      context: context,
      updates: pendingUpdates,
      showSendButton: true,
      onSend: () async {
        await _sendPendingUpdates(context);
      },
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
      context.read<FetchStockBloc>().add(StartSyncEvent(ipAddress: ""));
      context.read<FetchCustomerBloc>().add(
        StartCustomerSyncEvent(ipAddress: ""),
      );
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
            _promptSendPendingStockUpdates(context);
          }
        },
        builder: (context, state) {
          final colors = context.appColors;
          final bool isDark = colors.isDark;
          if (state is FetchStockProgress) {
            return Container(
              margin: const EdgeInsets.only(top: 5, bottom: 2),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? colors.surface : kSecondaryColor,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: isDark ? colors.cardShadow : kThirdColor.withOpacity(0.05),
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
                        state.message,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isDark ? colors.onSurface : null,
                        ),
                      ),
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
                        isDark ? colors.surfaceAlt : Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(kPrimaryColor),
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "${state.currentCount} / ${state.totalCount} records",
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? colors.onSurfaceMuted : kGreyColor,
                    ),
                  ),
                ],
              ),
            );
          } else if (state is FetchStockError) {
            final scheme = Theme.of(context).colorScheme;
            return Container(
              margin: const EdgeInsets.only(top: 5, bottom: 2),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? scheme.errorContainer : Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark ? scheme.errorContainer : Colors.red.shade200,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: isDark ? scheme.onErrorContainer : kErrorColor,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      state.message,
                      style: TextStyle(
                        color: isDark ? scheme.onErrorContainer : kErrorColor,
                        fontSize: 14,
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
                color: isDark ? colors.surface : Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark ? colors.divider : Colors.green.shade200,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle,
                    color: isDark ? colors.onSurfaceMuted : Colors.green,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Stock Database Updated Successfully",
                    style: TextStyle(
                      color: isDark ? colors.onSurfaceMuted : Colors.green.shade800,
                      fontSize: 14,
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
