import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rmstock_scanner/entities/vos/stock_vo.dart';
import 'package:rmstock_scanner/entities/vos/pending_stock_update_vo.dart';
import 'package:rmstock_scanner/features/stock_lookup/presentation/BLoC/stock_lookup_bloc.dart';
import 'package:rmstock_scanner/features/stock_lookup/presentation/BLoC/stock_lookup_events.dart';
import 'package:rmstock_scanner/features/stock_lookup/presentation/BLoC/stock_lookup_states.dart';
import 'package:rmstock_scanner/features/stock_lookup/presentation/screens/stock_details_screen.dart';
import 'package:rmstock_scanner/features/stock_lookup/presentation/widgets/stock_thumbnail_tile.dart';
import 'package:rmstock_scanner/local_db/local_db_dao.dart';
import 'package:rmstock_scanner/utils/navigation_extension.dart';

import '../../../../constants/colors.dart';
import '../../../../utils/dialog_size_utils.dart';

class PendingStockUpdatesTile extends StatefulWidget {
  const PendingStockUpdatesTile({super.key});

  @override
  State<PendingStockUpdatesTile> createState() =>
      _PendingStockUpdatesTileState();
}

class _PendingStockUpdatesTileState extends State<PendingStockUpdatesTile> {
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PendingStockUpdatesBloc, PendingStockUpdatesState>(
      listener: (context, state) async {
        if (state is PendingStockUpdatesCountLoaded) {
          setState(() {
            _count = state.count;
          });
        }
        if (state is PendingStockUpdatesLoaded) {
          setState(() {
            _count = state.updates.length;
          });
          await _showPendingDialog(context, state.updates);
        }
      },
      builder: (context, state) {
        if (_count <= 0) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15.0),
          child: InkWell(
            onTap: () {
              context.read<PendingStockUpdatesBloc>().add(
                LoadPendingStockUpdatesEvent(),
              );
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              margin: const EdgeInsets.only(top: 5, bottom: 8),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.sync_problem, color: Colors.orange.shade800, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "$_count stock updates not sent to RetailManager",
                      style: TextStyle(
                        color: Colors.orange.shade800,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(Icons.chevron_right, color: Colors.orange.shade800, size: 18),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showPendingDialog(
    BuildContext context,
    List<PendingStockUpdateVO> updates,
  ) async {
    if (updates.isEmpty) return;

    final shopfront =
        (await LocalDbDAO.instance.getShopfrontName() ?? '').trim();
    final List<num> ids = updates.map<num>((e) => e.stockId).toList();
    final stockMap = await LocalDbDAO.instance.getStocksByIds(
      shopfront: shopfront,
      stockIds: ids,
    );
    final stocks = ids
        .map((id) => stockMap[id])
        .whereType<StockVO>()
        .toList();

    if (!context.mounted) return;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: dialogInsetPadding(dialogContext),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: kBgColor,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: kPrimaryColor.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.sync_problem,
                        color: kPrimaryColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Pending Stock Updates",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: kThirdColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  "${stocks.length} item(s) are saved locally and not sent yet.",
                  style: TextStyle(
                    fontSize: 12.5,
                    color: kThirdColor.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  constraints: const BoxConstraints(maxHeight: 380),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: kSecondaryColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: kGreyColor.withOpacity(0.2)),
                  ),
                  child: stocks.isEmpty
                      ? const Text("No pending stock updates found.")
                      : ListView.separated(
                          shrinkWrap: true,
                          itemCount: stocks.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final stock = stocks[index];
                            return _PendingStockTile(
                              stock: stock,
                              onTap: () async {
                                Navigator.of(dialogContext).pop();
                                await context.navigateToNext(
                                  StockDetailsScreen(stock: stock),
                                );
                                if (!context.mounted) return;
                                context
                                    .read<PendingStockUpdatesBloc>()
                                    .add(LoadPendingStockUpdatesCountEvent());
                              },
                            );
                          },
                        ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: kPrimaryColor.withOpacity(0.4),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text("Close", style: TextStyle(color: kPrimaryColor)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!context.mounted) return;
    context.read<PendingStockUpdatesBloc>().add(
      LoadPendingStockUpdatesCountEvent(),
    );
  }
}

class _PendingStockTile extends StatelessWidget {
  final StockVO stock;
  final VoidCallback onTap;

  const _PendingStockTile({required this.stock, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bool isTablet = MediaQuery.of(context).size.shortestSide >= 600;
    final double textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
    final double uiScale = isTablet
        ? (1.0 + ((textScale - 1.0) * 0.35)).clamp(1.0, 1.2)
        : 1.0;
    final double thumbnailSize = (isTablet ? 44 : 36) * uiScale;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Container(
              width: thumbnailSize,
              height: thumbnailSize,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(isTablet ? 8 : 6),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(isTablet ? 8 : 6),
                child: Hero(
                  tag: 'pending_stock_${stock.stockID}',
                  child: StockThumbnailTile(stock: stock),
                ),
              ),
            ),
            SizedBox(width: (isTablet ? 17 : 15) * uiScale),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stock.description,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: kThirdColor,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    stock.barcode,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                      color: kPrimaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: kGreyColor, size: 20),
          ],
        ),
      ),
    );
  }
}
