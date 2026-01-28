// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rmstock_scanner/constants/colors.dart';
import 'package:rmstock_scanner/constants/txt_styles.dart';
import 'package:rmstock_scanner/entities/vos/counted_stock_vo.dart';
import 'package:rmstock_scanner/entities/vos/stocktake_history_session_row.dart';
import 'package:rmstock_scanner/features/stocktake/presentation/BLoC/stocktake_bloc.dart';
import 'package:rmstock_scanner/features/stocktake/presentation/BLoC/stocktake_events.dart';
import 'package:rmstock_scanner/features/stocktake/presentation/BLoC/stocktake_states.dart';
import 'package:rmstock_scanner/features/stocktake/presentation/widgets/empty_stock_state_widget.dart';
import 'package:rmstock_scanner/utils/navigation_extension.dart';

import 'package:excel/excel.dart';
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
    return WillPopScope(
      onWillPop: () async {
        if (mounted) {
          context.read<StocktakeHistoryBloc>().add(LoadHistorySessionsEvent());
        }
        return true; // allow pop
      },
      child: Scaffold(
        backgroundColor: kBgColor,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(15, 15, 15, 10),
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
                          icon: const Icon(
                            Icons.arrow_back_ios,
                            color: kPrimaryColor,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          "History Details",
                          style: getSmartTitle(
                            color: kThirdColor,
                            fontSize: 16,
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

                        return IconButton(
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
                          icon: Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: Icon(
                              Icons.screen_share_outlined,
                              color: canExport ? Colors.green : kGreyColor,
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
                            fontSize: 14,
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

                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(15, 5, 15, 15),
                        separatorBuilder: (_, _) => const SizedBox(height: 7),
                        itemCount: state.items.length,
                        itemBuilder: (_, i) => _itemTile(state.items[i]),
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

  Widget _itemTile(CountedStockVO stock) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
          const Icon(Icons.inventory_2_outlined, size: 18, color: kGreyColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stock.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: getSmartTitle(color: kThirdColor, fontSize: 14),
                ),
                Text(
                  stock.barcode,
                  style: const TextStyle(
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
    );
  }
}
