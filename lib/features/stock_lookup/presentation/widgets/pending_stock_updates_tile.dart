import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rmstock_scanner/entities/vos/stock_vo.dart';
import 'package:rmstock_scanner/entities/vos/pending_stock_update_vo.dart';
import 'package:rmstock_scanner/entities/vos/pricing_rules.dart';
import 'package:rmstock_scanner/features/stock_lookup/presentation/BLoC/stock_lookup_bloc.dart';
import 'package:rmstock_scanner/features/stock_lookup/presentation/BLoC/stock_lookup_events.dart';
import 'package:rmstock_scanner/features/stock_lookup/presentation/BLoC/stock_lookup_states.dart';
import 'package:rmstock_scanner/features/stock_lookup/presentation/screens/stock_details_screen.dart';
import 'package:rmstock_scanner/features/stock_lookup/presentation/widgets/stock_thumbnail_tile.dart';
import 'package:rmstock_scanner/local_db/local_db_dao.dart';
import 'package:rmstock_scanner/utils/navigation_extension.dart';

import '../../../../constants/colors.dart';
import '../../../../constants/theme_colors.dart';
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
          if (state.showDialog) {
            await _showPendingDialog(context, state.updates);
          }
        }
      },
      builder: (context, state) {
        if (state is PendingStockUpdatesLoading) {
          return _buildLoadingTile();
        }
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
                color: Colors.orange.shade800.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade400),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.sync_problem, color: Colors.orange.shade800, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "$_count stock update(s) not sent to RetailManager",
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
    await showPendingStockUpdatesDialog(
      context: context,
      updates: updates,
      showSendButton: false,
    );
  }

  Widget _buildLoadingTile() {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15.0),
      child: Container(
        margin: const EdgeInsets.only(top: 5, bottom: 8),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.divider),
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CupertinoActivityIndicator(
                color: kPrimaryColor,
                radius: 10,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                "Processing pending stock updates...",
                style: TextStyle(
                  color: colors.onSurface,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PendingStockEntry {
  final PendingStockUpdateVO update;
  final StockVO? stock;

  const _PendingStockEntry({required this.update, required this.stock});
}

class _PendingStockTile extends StatelessWidget {
  final PendingStockUpdateVO update;
  final StockVO? stock;
  final VoidCallback? onTap;

  const _PendingStockTile({
    required this.update,
    required this.stock,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final bool isTablet = MediaQuery.of(context).size.shortestSide >= 600;
    final double textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
    final double uiScale = isTablet
        ? (1.0 + ((textScale - 1.0) * 0.35)).clamp(1.0, 1.2)
        : 1.0;
    final double thumbnailSize = (isTablet ? 44 : 36) * uiScale;

    final String title = stock?.description ?? 'Stock #${update.stockId}';
    final String barcode = stock?.barcode ?? 'Pending update';
    final bool canNavigate = onTap != null;

    final tile = Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        boxShadow: [
          BoxShadow(
            color: colors.cardShadow,
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
              child: stock == null
                  ? Container(
                      color: kPrimaryColor.withOpacity(0.1),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.inventory_2_outlined,
                        color: kPrimaryColor.withOpacity(0.8),
                        size: 18,
                      ),
                    )
                  : Hero(
                      tag: 'pending_stock_${stock!.stockID}',
                      child: StockThumbnailTile(stock: stock!),
                    ),
            ),
          ),
          SizedBox(width: (isTablet ? 17 : 15) * uiScale),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  barcode,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    color: kPrimaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (update.errorMessage != null &&
                    update.errorMessage!.trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      update.errorMessage!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (canNavigate)
            Icon(Icons.chevron_right, color: colors.onSurfaceMuted, size: 20),
        ],
      ),
    );

    if (!canNavigate) return tile;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: tile,
    );
  }
}

PricingRules? _pendingPricingRules(dynamic payload) {
  if (payload is Map<String, dynamic>) {
    return PricingRules.fromJson(payload);
  }
  if (payload is Map) {
    return PricingRules.fromJson(Map<String, dynamic>.from(payload));
  }
  return null;
}

StockVO _stockFromPendingPayload(PendingStockUpdateVO update) {
  final payload = update.payload;
  final int stockId = (payload['stock_id'] as num?)?.toInt() ??
      (payload['stockId'] as num?)?.toInt() ??
      update.stockId;

  final Map<String, dynamic> item = {
    'stock_id': stockId,
    'barcode': payload['barcode'] ?? '',
    'description': payload['description'] ?? '',
    'sell': payload['sell'] ?? 0,
    'cost': payload['cost'] ?? 0,
    'goods_tax': payload['goods_tax'] ?? '',
    'sales_tax': payload['sales_tax'] ?? '',
    'custom1': payload['custom1'],
    'custom2': payload['custom2'],
    'pricing_rules': payload['pricing_rules'],
    'date_modified': payload['date_modified'] ?? DateTime.now().toIso8601String(),
  };

  final stock = StockVO.fromApiItem(item);
  final rules = _pendingPricingRules(payload['pricing_rules']);
  return StockVO(
    stockID: stock.stockID,
    barcode: stock.barcode,
    description: stock.description,
    deptName: stock.deptName,
    deptID: stock.deptID,
    custom1: stock.custom1,
    custom2: stock.custom2,
    longDescription: stock.longDescription,
    supplier: stock.supplier,
    category1: stock.category1,
    category2: stock.category2,
    category3: stock.category3,
    cost: stock.cost,
    sell: stock.sell,
    inactive: stock.inactive,
    quantity: stock.quantity,
    laybyQuantity: stock.laybyQuantity,
    salesOrderQuantity: stock.salesOrderQuantity,
    dateCreated: stock.dateCreated,
    orderThreshold: stock.orderThreshold,
    orderQuantity: stock.orderQuantity,
    allowFractions: stock.allowFractions,
    package: stock.package,
    staticQuantity: stock.staticQuantity,
    pictureFileName: stock.pictureFileName,
    imageUrl: stock.imageUrl,
    goodsTax: stock.goodsTax,
    salesTax: stock.salesTax,
    dateModified: stock.dateModified,
    freight: stock.freight,
    tareWeight: stock.tareWeight,
    unitOfMeasure: stock.unitOfMeasure,
    weighted: stock.weighted,
    trackSerial: stock.trackSerial,
    lastSaleDate: stock.lastSaleDate,
    pricingRules: rules,
  );
}

Future<void> showPendingStockUpdatesDialog({
  required BuildContext context,
  required List<PendingStockUpdateVO> updates,
  required bool showSendButton,
  Future<void> Function()? onSend,
}) async {
  if (updates.isEmpty) return;

  final entries = updates
      .map(
        (update) => _PendingStockEntry(
          update: update,
          stock: _stockFromPendingPayload(update),
        ),
      )
      .toList();

  if (!context.mounted) return;

  await showDialog(
    context: context,
    builder: (dialogContext) {
      final dialogEntries = List<_PendingStockEntry>.from(entries);
      return StatefulBuilder(
        builder: (context, setDialogState) {
          final colors = context.appColors;
          final bool isDark = colors.isDark;
          return Dialog(
            insetPadding: dialogInsetPadding(dialogContext),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side:
                  isDark ? const BorderSide(color: Colors.white30) : BorderSide.none,
            ),
            backgroundColor: isDark ? colors.surfaceAlt : colors.surface,
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
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: colors.onSurface,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        icon: Icon(Icons.close, color: colors.onSurface),
                        tooltip: 'Close',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "${dialogEntries.length} item(s) are saved locally and not sent yet.",
                    style: TextStyle(
                      fontSize: 12.5,
                      color: colors.onSurfaceMuted,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 380),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark ? Colors.white24 : colors.divider,
                      ),
                    ),
                    child: dialogEntries.isEmpty
                        ? Text(
                            "No pending stock updates found.",
                            style: TextStyle(color: colors.onSurfaceMuted),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            itemCount: dialogEntries.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final entry = dialogEntries[index];
                              return Dismissible(
                                key: ValueKey('pending_stock_${entry.update.id}'),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade400,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.delete,
                                    color: Colors.white,
                                  ),
                                ),
                                onDismissed: (direction) async {
                                  await LocalDbDAO.instance.deletePendingStockUpdates(
                                    [entry.update.id],
                                  );
                                  setDialogState(() {
                                    dialogEntries.removeWhere(
                                      (item) => item.update.id == entry.update.id,
                                    );
                                  });
                                  if (!dialogContext.mounted) return;
                                  dialogContext
                                      .read<PendingStockUpdatesBloc>()
                                      .add(LoadPendingStockUpdatesCountEvent());
                                  if (dialogEntries.isEmpty) {
                                    Navigator.of(dialogContext).pop();
                                  }
                                },
                                child: _PendingStockTile(
                                  update: entry.update,
                                  stock: entry.stock,
                                  onTap: entry.stock == null
                                      ? null
                                      : () async {
                                          Navigator.of(dialogContext).pop();
                                          await context.navigateToNext(
                                            StockDetailsScreen(
                                              stock: entry.stock!,
                                            ),
                                          );
                                          if (!context.mounted) return;
                                          context
                                              .read<PendingStockUpdatesBloc>()
                                              .add(
                                                LoadPendingStockUpdatesCountEvent(),
                                              );
                                        },
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: dialogEntries.isEmpty
                              ? null
                              : () async {
                                  final ids = dialogEntries
                                      .map((entry) => entry.update.id)
                                      .toList();
                                  await LocalDbDAO.instance
                                      .deletePendingStockUpdates(ids);
                                  if (!dialogContext.mounted) return;
                                  dialogContext
                                      .read<PendingStockUpdatesBloc>()
                                      .add(LoadPendingStockUpdatesCountEvent());
                                  Navigator.of(dialogContext).pop();
                                },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: kErrorColor.withOpacity(0.6),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            "Delete All",
                            style: TextStyle(color: kErrorColor),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: showSendButton
                            ? ElevatedButton(
                                onPressed: dialogEntries.isEmpty
                                    ? null
                                    : () async {
                                        Navigator.of(dialogContext).pop();
                                        if (onSend != null) {
                                          await onSend();
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: kPrimaryColor,
                                  foregroundColor: colors.onHero,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Text("Send"),
                              )
                            : OutlinedButton(
                                onPressed: () => Navigator.of(dialogContext).pop(),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                    color: kPrimaryColor.withOpacity(0.4),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Text(
                                  "Close",
                                  style: TextStyle(color: kPrimaryColor),
                                ),
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
    },
  );

  if (!context.mounted) return;
  context.read<PendingStockUpdatesBloc>().add(
    LoadPendingStockUpdatesCountEvent(),
  );
}
