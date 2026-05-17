// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rmmobile/constants/colors.dart';
import 'package:rmmobile/constants/theme_colors.dart';
import 'package:rmmobile/constants/txt_styles.dart';
import 'package:rmmobile/entities/vos/counted_stock_vo.dart';
import 'package:rmmobile/entities/vos/stocktake_history_session_row.dart';
import 'package:rmmobile/features/stocktake/presentation/BLoC/stocktake_bloc.dart';
import 'package:rmmobile/features/stocktake/presentation/BLoC/stocktake_events.dart';
import 'package:rmmobile/features/stocktake/presentation/BLoC/stocktake_states.dart';
import 'package:rmmobile/features/stocktake/presentation/widgets/empty_stock_state_widget.dart';
import 'package:rmmobile/features/stocktake/presentation/widgets/stock_details_readonly_dialog.dart';
import 'package:rmmobile/utils/navigation_extension.dart';
import 'package:rmmobile/utils/responsive_utils.dart';

import 'package:excel/excel.dart' hide Border;
import 'package:share_plus/share_plus.dart';

import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';
import 'package:file_selector/file_selector.dart';

class StocktakeHistoryDetailsScreen extends StatefulWidget {
  final StocktakeHistorySessionRow session;
  const StocktakeHistoryDetailsScreen({super.key, required this.session});

  @override
  State<StocktakeHistoryDetailsScreen> createState() =>
      _StocktakeHistoryDetailsScreenState();
}

class _StocktakeHistoryDetailsScreenState
    extends State<StocktakeHistoryDetailsScreen> {
  Future<String?> _exportSessionToExcel({
    required StocktakeHistorySessionRow session,
    required List<CountedStockVO> items,
  }) async {
    // 1. Generate Excel Data (Same as before)
    final excel = Excel.createExcel();
    final sheet = excel['Sheet1'];

    sheet.appendRow([
      TextCellValue("stock_id"),
      TextCellValue("barcode"),
      TextCellValue("description"),
      TextCellValue("quantity"),
      TextCellValue("stocktake_date"),
      TextCellValue("date_modified"),
      TextCellValue("shopfront"),
      TextCellValue("session_id"),
    ]);

    for (final s in items) {
      sheet.appendRow([
        IntCellValue(s.stockID),
        TextCellValue(s.barcode),
        TextCellValue(s.description),
        DoubleCellValue(double.tryParse(s.quantity.toString()) ?? 0),
        TextCellValue(s.stocktakeDate.toIso8601String()),
        TextCellValue(s.dateModified.toIso8601String()),
        TextCellValue(session.shopfront),
        TextCellValue(session.sessionId),
      ]);
    }

    final bytes = excel.encode();
    if (bytes == null) throw Exception("Excel encode returned null.");

    String safe(String input) => input.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    final fileName =
        "stocktake_history_${safe(session.sessionId)}_${DateTime.now().millisecondsSinceEpoch}.xlsx";

    // 2. Platform Specific Saving Logic
    if (Platform.isAndroid || Platform.isIOS) {
      // Get temporary directory
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$fileName');

      // Write bytes
      await file.writeAsBytes(bytes, flush: true);

      // Open Share Sheet (User can select 'Save to Files', 'Email', etc.)
      // We wrap in a try-catch for UI safety, though Share usually succeeds
      try {
        final result = await Share.shareXFiles([
          XFile(file.path),
        ], text: 'Stocktake History Export');

        if (result.status == ShareResultStatus.success) {
          return "Shared successfully";
        } else {
          // User dismissed the sheet
          return null;
        }
      } catch (e) {
        throw Exception("Share failed: $e");
      }
    } else {
      final saveLocation = await getSaveLocation(
        suggestedName: fileName,
        acceptedTypeGroups: const [
          XTypeGroup(
            label: 'Excel',
            extensions: ['xlsx'],
            mimeTypes: [
              'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
            ],
          ),
        ],
      );

      if (saveLocation == null) {
        return null;
      }

      final xfile = XFile.fromData(
        Uint8List.fromList(bytes),
        name: fileName,
        mimeType:
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );

      await xfile.saveTo(saveLocation.path);
      return saveLocation.path;
    }
  }

  @override
  void initState() {
    super.initState();
    context.read<StocktakeHistoryBloc>().add(
      LoadHistoryItemsEvent(widget.session.sessionId),
    );
  }

  // @override
  // void dispose() {
  //   // Restore sessions state so history list is not blank when we pop back
  //   context.read<StocktakeHistoryBloc>().add(LoadHistorySessionsEvent());
  //   super.dispose();
  // }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final bool isDark = colors.isDark;
    final bool useDesktopNav = context.useDesktopNav;

    // Desktop sizing
    final double titleFontSize = useDesktopNav ? 14.0 : 16.0;
    final double backIconSize = useDesktopNav ? 16.0 : 18.0;
    final double topPadding = useDesktopNav ? 12.0 : 15.0;
    final double listPadding = useDesktopNav ? 12.0 : 15.0;
    final double itemSpacing = useDesktopNav ? 5.0 : 7.0;

    return WillPopScope(
      onWillPop: () async {
        if (mounted) {
          context.read<StocktakeHistoryBloc>().add(LoadHistorySessionsEvent());
        }
        return true; // allow pop
      },
      child: Scaffold(
        backgroundColor: colors.bg,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(topPadding, topPadding, topPadding, useDesktopNav ? 8 : 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            Future.microtask(() {
                              if (!mounted) return;
                              context.read<StocktakeHistoryBloc>().add(
                                LoadHistorySessionsEvent(),
                              );
                            });
                            context.navigateBack();
                          },
                          icon: Icon(
                            Icons.arrow_back_ios,
                            color: isDark ? Colors.white : kPrimaryColor,
                            size: backIconSize,
                          ),
                        ),
                        SizedBox(width: useDesktopNav ? 8 : 12),
                        Text(
                          "History Details",
                          style: getSmartTitle(
                            color: isDark ? Colors.white : colors.onSurface,
                            fontSize: titleFontSize,
                          ),
                        ),
                      ],
                    ),

                    BlocBuilder<StocktakeHistoryBloc, StocktakeHistoryState>(
                      builder: (context, state) {
                        final canExport =
                            state is StocktakeHistoryItemsLoaded &&
                            state.sessionId == widget.session.sessionId &&
                            state.items.isNotEmpty;

                        return Padding(
                          padding: EdgeInsets.only(right: useDesktopNav ? 8 : 12),
                          child: IconButton(
                            onPressed: canExport
                                ? () async {
                                    try {
                                      final items = (state).items;
                                      final path = await _exportSessionToExcel(
                                        session: widget.session,
                                        items: items,
                                      );

                                      if (!mounted) return;

                                      if (path == null) {
                                        showTopSnackBar(
                                          Overlay.of(context),
                                          const CustomSnackBar.info(
                                            message: "Export cancelled.",
                                          ),
                                        );
                                        return;
                                      }

                                      showTopSnackBar(
                                        Overlay.of(context),
                                        CustomSnackBar.success(
                                          message: "Exported to: $path",
                                        ),
                                      );
                                    } catch (e) {
                                      if (!mounted) return;
                                      showTopSnackBar(
                                        Overlay.of(context),
                                        CustomSnackBar.error(
                                          message: "Export failed: $e",
                                        ),
                                      );
                                    }
                                  }
                                : null,
                            icon: SizedBox(
                              width: useDesktopNav ? 24 : 28,
                              height: useDesktopNav ? 26 : 30,
                              child: Image.asset(
                                "assets/images/excel.png",
                                fit: BoxFit.fill,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              Expanded(
                child: BlocBuilder<StocktakeHistoryBloc, StocktakeHistoryState>(
                  builder: (context, state) {
                    if (state is StocktakeHistoryLoading) {
                      return const Center(child: CupertinoActivityIndicator());
                    }
                    if (state is StocktakeHistoryError) {
                      return Center(
                        child: Text(
                          state.message,
                          style: getSmartTitle(
                            color: kErrorColor,
                            fontSize: useDesktopNav ? 12 : 14,
                          ),
                        ),
                      );
                    }
                    if (state is StocktakeHistoryItemsLoaded &&
                        state.sessionId == widget.session.sessionId) {
                      if (state.items.isEmpty) {
                        return EmptyStockState(
                          message: "No items in this session",
                          onRetry: () {},
                        );
                      }

                      return Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: useDesktopNav ? 800 : double.infinity),
                          child: ListView.separated(
                            padding: EdgeInsets.fromLTRB(listPadding, 5, listPadding, listPadding),
                            separatorBuilder: (_, _) => SizedBox(height: itemSpacing),
                            itemCount: state.items.length,
                            itemBuilder: (_, i) => _itemTile(state.items[i], useDesktopNav),
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _itemTile(CountedStockVO stock, bool useDesktopNav) {
    final colors = context.appColors;
    final bool isDark = colors.isDark;

    // Desktop sizing
    final double tilePaddingH = useDesktopNav ? 12.0 : 16.0;
    final double tilePaddingV = useDesktopNav ? 8.0 : 10.0;
    final double titleFontSize = useDesktopNav ? 12.0 : 14.0;
    final double barcodeFontSize = useDesktopNav ? 11.0 : 12.0;
    final double qtyFontSize = useDesktopNav ? 12.0 : 14.0;
    final double iconSize = useDesktopNav ? 16.0 : 18.0;
    final double borderRadius = useDesktopNav ? 8.0 : 10.0;

    return InkWell(
      onTap: () {
        context.read<StockDetailsBloc>().add(
          FetchStockDetailsByID(stockId: stock.stockID, qty: stock.quantity),
        );

        showDialog(
          context: context,

          builder: (context) => const StockDetailsReadOnlyDialog(),
        );
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: tilePaddingH, vertical: tilePaddingV),
        decoration: BoxDecoration(
          color: isDark ? colors.surfaceAlt : colors.surface,
          borderRadius: BorderRadius.circular(borderRadius),
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
              size: iconSize,
              color: Colors.green,
            ),
            SizedBox(width: useDesktopNav ? 10 : 12),
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
                      fontSize: titleFontSize,
                    ),
                  ),
                  Text(
                    stock.barcode,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: barcodeFontSize,
                      fontWeight: FontWeight.w600,
                      color: kPrimaryColor,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: useDesktopNav ? 8 : 10),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: useDesktopNav ? 8 : 10,
                vertical: useDesktopNav ? 3 : 4,
              ),
              decoration: BoxDecoration(
                color: kPrimaryColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(useDesktopNav ? 6 : 8),
              ),
              child: Text(
                stock.quantity.toString(),
                style: TextStyle(
                  fontSize: qtyFontSize,
                  fontWeight: FontWeight.w900,
                  color: kPrimaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
