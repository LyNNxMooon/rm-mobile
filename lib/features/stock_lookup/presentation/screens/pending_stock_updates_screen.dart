import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rmstock_scanner/entities/vos/pending_stock_update_vo.dart';
import 'package:rmstock_scanner/entities/vos/pricing_rules.dart';
import 'package:rmstock_scanner/entities/vos/stock_vo.dart';
import 'package:rmstock_scanner/features/stock_lookup/presentation/BLoC/stock_lookup_bloc.dart';
import 'package:rmstock_scanner/features/stock_lookup/presentation/BLoC/stock_lookup_events.dart';
import 'package:rmstock_scanner/features/stock_lookup/presentation/BLoC/stock_lookup_states.dart';
import 'package:rmstock_scanner/features/stock_lookup/presentation/screens/stock_details_screen.dart';
import 'package:rmstock_scanner/features/stock_lookup/presentation/widgets/stock_thumbnail_tile.dart';
import 'package:rmstock_scanner/utils/navigation_extension.dart';
import 'package:rmstock_scanner/features/home_page/presentation/BLoC/home_screen_bloc.dart';
import 'package:rmstock_scanner/features/home_page/presentation/BLoC/home_screen_events.dart';
import 'package:rmstock_scanner/features/home_page/presentation/BLoC/home_screen_states.dart';

import '../../../../constants/colors.dart';
import '../../../../constants/theme_colors.dart';
import '../../../../constants/txt_styles.dart';

class PendingStockUpdatesScreen extends StatefulWidget {
  final bool showSendButton;
  final Future<void> Function()? onSend;

  const PendingStockUpdatesScreen({
    super.key,
    required this.showSendButton,
    this.onSend,
  });

  @override
  State<PendingStockUpdatesScreen> createState() =>
      _PendingStockUpdatesScreenState();
}

class _PendingStockUpdatesScreenState extends State<PendingStockUpdatesScreen> {
  List<PendingStockUpdateVO> _updates = const [];

  @override
  void initState() {
    super.initState();
    context.read<PendingStockUpdatesBloc>().add(
      LoadPendingStockUpdatesEvent(showDialog: false),
    );
  }

  Future<void> _sendPendingUpdates(
    PendingStockUpdatesBloc pendingBloc,
    FetchStockBloc fetchBloc,
    ScaffoldMessengerState messenger,
  ) async {
    pendingBloc.add(SendPendingStockUpdatesEvent());

    final result = await pendingBloc.stream.firstWhere(
      (state) =>
          state is PendingStockUpdatesSent ||
          state is PendingStockUpdatesError,
    );

    if (result is PendingStockUpdatesSent) {
      messenger.showSnackBar(
        SnackBar(content: Text(result.message)),
      );
      final loadedState = await pendingBloc.stream.firstWhere(
        (state) => state is PendingStockUpdatesLoaded,
      );
      if (loadedState is PendingStockUpdatesLoaded &&
          loadedState.updates.isEmpty) {
        await pendingBloc.stream.firstWhere(
          (state) => state is PendingStockUpdatesSyncReady,
        );
        await Future<void>.delayed(const Duration(seconds: 2));
        if (fetchBloc.state is! FetchStockProgress) {
          fetchBloc.add(StartSyncEvent(ipAddress: ""));
        }
      }
    } else if (result is PendingStockUpdatesError) {
      messenger.showSnackBar(
        SnackBar(content: Text(result.message)),
      );
    }

    pendingBloc.add(
      LoadPendingStockUpdatesEvent(showDialog: false),
    );
    pendingBloc.add(
      LoadPendingStockUpdatesCountEvent(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final bool isDark = colors.isDark;

    return Scaffold(
      backgroundColor: isDark ? colors.bg : kBgColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 18,
        title: Text(
          'Pending Stock Updates',
          style: getSmartTitle(
            color: isDark ? Colors.white : colors.onSurface,
            fontSize: 16,
          ),
        ),
        backgroundColor: isDark ? colors.bg : kBgColor,
        foregroundColor: colors.onSurface,
        elevation: 0,
      ),
      body: SafeArea(
        child: BlocConsumer<PendingStockUpdatesBloc, PendingStockUpdatesState>(
          listener: (context, state) {
            if (state is PendingStockUpdatesLoaded) {
              setState(() {
                _updates = state.updates;
              });
            }
          },
          builder: (context, state) {
            if (state is PendingStockUpdatesLoading && _updates.isEmpty) {
              return _buildLoadingTile(context);
            }

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "${_updates.length} item(s) are saved locally and not sent yet.",
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: colors.onSurfaceMuted,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: _updates.isEmpty
                      ? Center(
                          child: Text(
                            "No pending stock updates found.",
                            style: TextStyle(color: colors.onSurfaceMuted),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 8,
                          ),
                          itemCount: _updates.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final update = _updates[index];
                            final stock = _stockFromPendingPayload(update);
                            return Dismissible(
                              key: ValueKey('pending_stock_${update.id}'),
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
                              onDismissed: (direction) {
                                context
                                    .read<PendingStockUpdatesBloc>()
                                    .add(
                                      DeletePendingStockUpdateEvent(
                                        id: update.id,
                                      ),
                                    );
                                setState(() {
                                  _updates = _updates
                                      .where((item) => item.id != update.id)
                                      .toList();
                                });
                              },
                              child: _PendingStockTile(
                                update: update,
                                stock: stock,
                                onTap: () async {
                                  await context.navigateToNext(
                                    StockDetailsScreen(stock: stock),
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
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 6, 18, 18),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _updates.isEmpty
                              ? null
                              : () {
                                  final ids =
                                      _updates.map((entry) => entry.id).toList();
                                  context
                                      .read<PendingStockUpdatesBloc>()
                                      .add(
                                        DeleteAllPendingStockUpdatesEvent(
                                          ids: ids,
                                        ),
                                      );
                                  Navigator.of(context).pop();
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
                        child: widget.showSendButton
                            ? ElevatedButton(
                                onPressed: _updates.isEmpty
                                    ? null
                                    : () async {
                                  final pendingBloc = context
                                    .read<PendingStockUpdatesBloc>();
                                  final messenger =
                                    ScaffoldMessenger.of(context);
                                        final onSend = widget.onSend;
                                        final fetchBloc =
                                            context.read<FetchStockBloc>();
                                  Navigator.of(context).pop();
                                        if (onSend != null) {
                                          await onSend();
                                        } else {
                                          await _sendPendingUpdates(
                                            pendingBloc,
                                            fetchBloc,
                                            messenger,
                                          );
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
                                onPressed: () => Navigator.of(context).pop(),
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
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildLoadingTile(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Container(
        margin: const EdgeInsets.only(top: 12, bottom: 8),
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
    final bool isDark = colors.isDark;
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
        color: isDark
            ? Color.lerp(colors.surface, Colors.white, 0.06)
            : colors.surface,
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        border: isDark
            ? Border.all(color: Colors.white.withOpacity(0.18))
            : null,
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.35)
                : colors.cardShadow,
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
