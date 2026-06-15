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
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _searchFocused = false;
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
    _searchFocusNode.addListener(() {
      if (_searchFocused != _searchFocusNode.hasFocus) {
        setState(() => _searchFocused = _searchFocusNode.hasFocus);
      }
    });
    context.read<StocktakeHistoryBloc>().add(
      LoadHistoryItemsEvent(widget.session.sessionId),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  List<CountedStockVO> _filterItems(List<CountedStockVO> items) {
    if (_searchQuery.isEmpty) return items;
    final query = _searchQuery.toLowerCase();
    return items.where((item) {
      return item.barcode.toLowerCase().contains(query) ||
          item.description.toLowerCase().contains(query);
    }).toList();
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

    return WillPopScope(
      onWillPop: () async {
        if (mounted) {
          context.read<StocktakeHistoryBloc>().add(LoadHistorySessionsEvent());
        }
        return true; // allow pop
      },
      child: Scaffold(
        backgroundColor: isDark ? Colors.black : Colors.white,
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

              // Search bar
              _buildSearchBar(colors, isDark, useDesktopNav),
              const SizedBox(height: 10),
              
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

                      final filteredItems = _filterItems(state.items);
                      
                      if (filteredItems.isEmpty) {
                        return EmptyStockState(
                          message: "No items match your search",
                          onRetry: () {
                            setState(() {
                              _searchQuery = "";
                              _searchController.clear();
                            });
                          },
                        );
                      }

                      return Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: useDesktopNav ? 800 : double.infinity),
                          child: ListView.separated(
                            padding: EdgeInsets.fromLTRB(listPadding, 5, listPadding, listPadding),
                            separatorBuilder: (_, _) => _buildFadedDivider(),
                            itemCount: filteredItems.length,
                            itemBuilder: (_, i) => _itemTile(filteredItems[i], useDesktopNav),
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

  Widget _buildSearchBar(AppThemeColors colors, bool isDark, bool useDesktopNav) {
    final bool isTablet = MediaQuery.of(context).size.shortestSide >= 600;
    final double textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
    final double uiScale = isTablet
        ? (1.0 + ((textScale - 1.0) * 0.35)).clamp(1.0, 1.2)
        : 1.0;
    final double containerHeight = useDesktopNav ? 36 : (isTablet ? 46 : 40) * uiScale;
    final double hintFontSize = useDesktopNav ? 12.0 : 13.0;
    final double iconSize = useDesktopNav ? 18.0 : 20.0;
    final double horizontalPadding = useDesktopNav ? 12.0 : 15.0;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: useDesktopNav ? 800 : double.infinity),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Container(
            height: containerHeight,
            decoration: BoxDecoration(
              color: isDark ? Colors.black : Colors.white,
              borderRadius: BorderRadius.circular(containerHeight / 2),
              border: Border.all(
                color: _searchFocused
                    ? kPrimaryColor
                    : (isDark ? Colors.white24 : kPrimaryColor.withOpacity(0.5)),
                width: _searchFocused ? 2 : 1,
              ),
            ),
            child: Center(
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                // Disable autocorrect and predictive text
                autocorrect: false,
                enableSuggestions: false,
                textAlignVertical: TextAlignVertical.center,
                style: TextStyle(
                  color: isDark ? Colors.white : colors.onSurface,
                  fontSize: hintFontSize,
                ),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: "Search barcode or description...",
                  hintStyle: TextStyle(
                    color: isDark ? Colors.white70 : colors.onSurfaceMuted,
                    fontSize: hintFontSize,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: isDark ? Colors.white70 : kPrimaryColor,
                    size: iconSize,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          onPressed: () {
                            setState(() {
                              _searchQuery = "";
                              _searchController.clear();
                            });
                          },
                          icon: Icon(
                            Icons.clear,
                            color: isDark ? Colors.white70 : colors.onSurfaceMuted,
                            size: iconSize,
                          ),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: useDesktopNav ? 10 : 12,
                  ),
                ),
              ),
            ),
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
    final double iconSize = 30;

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
        decoration: const BoxDecoration(color: Colors.transparent),
        child: Row(
          children: [
            Image.asset(
              'assets/images/sync.png',
              width: iconSize,
              height: iconSize,
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
            Text(
              stock.quantity.toString(),
              style: getSmartTitle(
                color: isDark ? Colors.white : colors.onSurface,
                fontSize: qtyFontSize,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFadedDivider() {
    final bool isDark = context.appColors.isDark;
    final Color lineColor = isDark ? Colors.white : Colors.black;
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
  }
}
