import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rmmobile/entities/vos/pending_stock_update_vo.dart';
import 'package:rmmobile/entities/vos/pricing_rules.dart';
import 'package:rmmobile/entities/vos/stock_vo.dart';
import 'package:rmmobile/features/stock_lookup/presentation/BLoC/stock_lookup_bloc.dart';
import 'package:rmmobile/features/stock_lookup/presentation/BLoC/stock_lookup_events.dart';
import 'package:rmmobile/features/stock_lookup/presentation/BLoC/stock_lookup_states.dart';
import 'package:rmmobile/features/stock_lookup/presentation/screens/stock_details_screen.dart';
import 'package:rmmobile/features/stock_lookup/presentation/widgets/stock_thumbnail_tile.dart';
import 'package:rmmobile/utils/navigation_extension.dart';
import 'package:rmmobile/features/home_page/presentation/BLoC/home_screen_bloc.dart';
import 'package:rmmobile/features/home_page/presentation/BLoC/home_screen_events.dart';
import 'package:rmmobile/features/home_page/presentation/BLoC/home_screen_states.dart';

import '../../../../constants/colors.dart';
import '../../../../constants/theme_colors.dart';
import '../../../../constants/txt_styles.dart';
import '../../../../utils/responsive_utils.dart';

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
    final bool useDesktopNav = context.useDesktopNav;
    
    // Desktop-specific sizing
    final double horizontalPadding = useDesktopNav ? 14.0 : 18.0;
    final double titleFontSize = useDesktopNav ? 13.0 : 16.0;
    final double subtitleFontSize = useDesktopNav ? 11.0 : 12.5;
    final double buttonFontSize = useDesktopNav ? 11.0 : 14.0;
    final double buttonVerticalPadding = useDesktopNav ? 8.0 : 12.0;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, size: useDesktopNav ? 20 : 24),
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleSpacing: 0,
        toolbarHeight: useDesktopNav ? 48 : kToolbarHeight,
        title: Text(
          'Pending Stock Updates',
          style: getSmartTitle(
            color: isDark ? Colors.white : colors.onSurface,
            fontSize: titleFontSize,
          ),
        ),
        backgroundColor: isDark ? Colors.black : Colors.white,
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
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "${_updates.length} item(s) are saved locally and not sent yet.",
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        fontSize: subtitleFontSize,
                        color: colors.onSurfaceMuted,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: useDesktopNav ? 8 : 10),
                Expanded(
                  child: _updates.isEmpty
                      ? Center(
                          child: Text(
                            "No pending stock updates found.",
                            style: TextStyle(
                              color: colors.onSurfaceMuted,
                              fontSize: useDesktopNav ? 12 : 14,
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: EdgeInsets.symmetric(
                            horizontal: horizontalPadding,
                            vertical: useDesktopNav ? 6 : 8,
                          ),
                          itemCount: _updates.length,
                          separatorBuilder: (context, index) {
                            final Color lineColor =
                                isDark ? Colors.white : Colors.black;
                            final double opacity = isDark ? 0.2 : 0.25;
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 8),
                              height: 0.5,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    lineColor.withOpacity(opacity),
                                    lineColor.withOpacity(opacity),
                                    Colors.transparent,
                                  ],
                                  stops: const [0.0, 0.2, 0.8, 1.0],
                                ),
                              ),
                            );
                          },
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
                  padding: EdgeInsets.fromLTRB(horizontalPadding, useDesktopNav ? 4 : 6, horizontalPadding, useDesktopNav ? 12 : 18),
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
                            padding: EdgeInsets.symmetric(vertical: buttonVerticalPadding),
                            side: BorderSide(
                              color: kErrorColor.withOpacity(0.6),
                            ),
                            shape: const StadiumBorder(),
                          ),
                          child: Text(
                            "Delete All",
                            style: TextStyle(
                              color: kErrorColor,
                              fontSize: buttonFontSize,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: useDesktopNav ? 8 : 10),
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
                                  padding: EdgeInsets.symmetric(vertical: buttonVerticalPadding),
                                  shape: const StadiumBorder(),
                                ),
                                child: Text(
                                  "Send",
                                  style: TextStyle(fontSize: buttonFontSize),
                                ),
                              )
                            : OutlinedButton(
                                onPressed: () => Navigator.of(context).pop(),
                                style: OutlinedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(vertical: buttonVerticalPadding),
                                  side: BorderSide(
                                    color: kPrimaryColor.withOpacity(0.4),
                                  ),
                                  shape: const StadiumBorder(),
                                ),
                                child: Text(
                                  "Close",
                                  style: TextStyle(
                                    color: kPrimaryColor,
                                    fontSize: buttonFontSize,
                                  ),
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
    final bool useDesktopNav = context.useDesktopNav;
    final double horizontalPadding = useDesktopNav ? 14.0 : 18.0;
    final double fontSize = useDesktopNav ? 11.0 : 13.0;
    final double indicatorRadius = useDesktopNav ? 8.0 : 10.0;
    
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Container(
        margin: EdgeInsets.only(top: useDesktopNav ? 10 : 12, bottom: useDesktopNav ? 6 : 8),
        padding: EdgeInsets.symmetric(vertical: useDesktopNav ? 8 : 10, horizontal: useDesktopNav ? 10 : 12),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(useDesktopNav ? 6 : 8),
          border: Border.all(color: colors.divider),
        ),
        child: Row(
          children: [
            SizedBox(
              width: useDesktopNav ? 14 : 18,
              height: useDesktopNav ? 14 : 18,
              child: CupertinoActivityIndicator(
                color: kPrimaryColor,
                radius: indicatorRadius,
              ),
            ),
            SizedBox(width: useDesktopNav ? 8 : 10),
            Expanded(
              child: Text(
                "Processing pending stock updates...",
                style: TextStyle(
                  color: colors.onSurface,
                  fontSize: fontSize,
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
    final bool isTablet = context.isTablet;
    final bool useDesktopNav = context.useDesktopNav;
    final double textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
    final double uiScale = isTablet
        ? (1.0 + ((textScale - 1.0) * 0.35)).clamp(1.0, 1.2)
        : 1.0;
    
    // Desktop-specific sizing
    final double thumbnailSize = useDesktopNav ? 32 : ((isTablet ? 44 : 36) * uiScale);
    final double titleFontSize = useDesktopNav ? 12.0 : 14.0;
    final double barcodeFontSize = useDesktopNav ? 11.0 : 13.0;
    final double conflictFontSize = useDesktopNav ? 10.0 : 11.5;
    final double errorFontSize = useDesktopNav ? 10.0 : 12.0;
    final double horizontalPadding = useDesktopNav ? 10.0 : 12.0;
    final double verticalPadding = useDesktopNav ? 8.0 : 10.0;
    final double borderRadius = useDesktopNav ? 8.0 : 10.0;
    final double iconSize = useDesktopNav ? 16.0 : 20.0;

    final String title = stock?.description ?? 'Stock #${update.stockId}';
    final String barcode = stock?.barcode ?? 'Pending update';
    final bool canNavigate = onTap != null;

    final tile = Container(
      decoration: const BoxDecoration(
        color: Colors.transparent,
      ),
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding),
      child: Row(
        children: [
          Container(
            width: thumbnailSize,
            height: thumbnailSize,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: stock == null
                  ? Container(
                      color: kPrimaryColor.withOpacity(0.1),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.inventory_2_outlined,
                        color: kPrimaryColor.withOpacity(0.8),
                        size: useDesktopNav ? 14 : 18,
                      ),
                    )
                  : Hero(
                      tag: 'pending_stock_${stock!.stockID}',
                      child: StockThumbnailTile(stock: stock!),
                    ),
            ),
          ),
          SizedBox(width: useDesktopNav ? 10 : ((isTablet ? 17 : 15) * uiScale)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface,
                  ),
                ),
                SizedBox(height: useDesktopNav ? 2 : 3),
                Text(
                  barcode,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: barcodeFontSize,
                    color: kPrimaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (update.hasConflict)
                  Padding(
                    padding: EdgeInsets.only(top: useDesktopNav ? 3 : 4),
                    child: Text(
                      "This record has been modified in RetailManager, please review and decide whether you still want to update it.",
                      style: TextStyle(
                        fontSize: conflictFontSize,
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                if (update.errorMessage != null &&
                    update.errorMessage!.trim().isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: useDesktopNav ? 3 : 4),
                    child: Text(
                      update.errorMessage!,
                      style: TextStyle(
                        fontSize: errorFontSize,
                        color: Colors.red.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (canNavigate)
            Icon(Icons.chevron_right, color: colors.onSurfaceMuted, size: iconSize),
        ],
      ),
    );

    if (!canNavigate) return tile;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(borderRadius),
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
    purchaseOrderQuantity: stock.purchaseOrderQuantity,
    csoQuantity: stock.csoQuantity,
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
