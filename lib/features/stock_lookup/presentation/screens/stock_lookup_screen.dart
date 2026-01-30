import 'dart:async';
import 'dart:ui' as ui;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:intl/intl.dart';
import 'package:rmstock_scanner/entities/vos/stock_vo.dart';
import 'package:rmstock_scanner/features/stock_lookup/presentation/BLoC/stock_lookup_states.dart';
import 'package:rmstock_scanner/features/stock_lookup/presentation/screens/stock_details_screen.dart';
import 'package:rmstock_scanner/features/stock_lookup/presentation/widgets/breathing_stock_loader.dart';
import 'package:rmstock_scanner/features/stock_lookup/presentation/widgets/stock_thumbnail_tile.dart';
import 'package:rmstock_scanner/utils/navigation_extension.dart';
import '../../../../../../constants/colors.dart';
import '../../../../constants/global_widgets.dart';
import '../../../../constants/txt_styles.dart';
import '../../../../entities/vos/filter_criteria.dart';
import '../BLoC/stock_lookup_bloc.dart';
import '../BLoC/stock_lookup_events.dart';
import '../widgets/filter_chip_row.dart';
import '../widgets/search_filter.dart';
import '../widgets/stock_lookup_appbar.dart';
import '../widgets/stock_lookup_scanner.dart';
import '../widgets/stocklookup_filter_dialog.dart';
import '../widgets/sync_info_widget.dart';

class Debouncer {
  final int milliseconds;
  Timer? _timer;

  Debouncer({required this.milliseconds});

  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }
}

class StockLookupScreen extends StatefulWidget {
  const StockLookupScreen({super.key});

  @override
  State<StockLookupScreen> createState() => _StockLookupScreenState();
}

class _StockLookupScreenState extends State<StockLookupScreen> {
  final ScrollController _scrollController = ScrollController();
  final Debouncer _debouncer = Debouncer(milliseconds: 500);

  // Default states
  String _selectedFilterChip = "Description"; // UI Label
  String _dbFilterCol = "description"; // DB Column Name
  String _searchQuery = "";

  final AudioPlayer _audioPlayer = AudioPlayer()
    ..setReleaseMode(ReleaseMode.stop);

  final _beepSource = AssetSource('audio/beep.mp3');

  bool isScanner = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Initial Load
    context.read<StockListBloc>().add(FetchFirstPageEvent());
    context.read<FilterOptionsBloc>().add(LoadFilterOptionsEvent());
  }

  void _onScroll() {
    if (_isBottom) {
      context.read<StockListBloc>().add(LoadMoreEvent());
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9); // Trigger at 90% scroll
  }

  String _mapChipToColumn(String label) {
    switch (label) {
      case "Barcode":
        return "Barcode";
      case "Description":
        return "description";
      case "Qty":
        return "quantity";
      case "Custom1":
        return "custom1";
      case "Cat1":
        return "cat1";
      case "Cat2":
        return "cat2";
      case "Cat3":
        return "cat3";

      case "Custom2":
        return "custom2";
      default:
        return "description";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: kBgColor,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              // shrinkWrap: true,
              // physics: const BouncingScrollPhysics(),
              children: [
                const SizedBox(height: 25),
                const StockLookupAppbar(), // Added const
                const SizedBox(height: 10),
                const Divider(
                  indent: 15,
                  endIndent: 15,
                  thickness: 0.5,
                  color: kGreyColor,
                ),
                const SyncInfoWidget(), // Added const
                // Chip states and Count Text
                BlocBuilder<StockListBloc, StockListState>(
                  builder: (context, state) {
                    final isAscending = state is StockListLoaded
                        ? state.isAscending
                        : true;
                    if (state is StockListLoaded) {
                      return Padding(
                        padding: const EdgeInsets.only(
                          left: 15,
                          right: 15,
                          bottom: 18,
                          top: 10,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: FilterChipRow(
                                selectedFilter: _selectedFilterChip,
                                isAscending: isAscending,
                                onFilterChanged: (newLabel) {
                                  setState(() {
                                    _selectedFilterChip = newLabel;
                                    _dbFilterCol = _mapChipToColumn(newLabel);
                                  });

                                  String searchCol = _dbFilterCol == "quantity"
                                      ? "description"
                                      : _dbFilterCol;

                                  final currentState = context
                                      .read<StockListBloc>()
                                      .state;
                                  FilterCriteria? currentFilters;
                                  if (currentState is StockListLoaded) {
                                    currentFilters = currentState.activeFilters;
                                  }

                                  context.read<StockListBloc>().add(
                                    FetchFirstPageEvent(
                                      query: _searchQuery,
                                      filterColumn: searchCol,
                                      sortColumn: _dbFilterCol,
                                      filters: currentFilters,
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "${state.stocks.length} of ${NumberFormat('#,###').format(state.totalCount)}",
                              style: const TextStyle(
                                color: kGreyColor,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return Padding(
                      padding: const EdgeInsets.only(
                        left: 15,
                        right: 15,
                        bottom: 18,
                        top: 10,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: FilterChipRow(
                              selectedFilter: _selectedFilterChip,
                              isAscending: isAscending,
                              onFilterChanged: (newLabel) {},
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "0 of ${NumberFormat('#,###').format(0)}",
                            style: const TextStyle(
                              color: kGreyColor,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                //Lookup Scanner
                scanner(),

                //Item lists state
                itemsList(),
              ],
            ),

            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: AnimatedPadding(
                duration: const Duration(milliseconds: 170),
                curve: Curves.easeOut,
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    // Glass blur background
                    ClipRect(
                      child: BackdropFilter(
                        filter: ui.ImageFilter.blur(sigmaX: 3.0, sigmaY: 3.0),
                        child: Container(
                          height: 100,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.white.withOpacity(0.0),
                                Colors.white.withOpacity(0.5),
                                Colors.white.withOpacity(0.9),
                              ],
                              stops: const [0.0, 0.4, 1.0],
                            ),
                          ),
                        ),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.only(
                        left: 20,
                        right: 20,
                        bottom: 42,
                      ),
                      child: _buildGlassSearchBar(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget scanner() {
    return AnimatedSize(
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, -0.08),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: isScanner
            ? StockLookupScanner(
                key: const ValueKey('scanner'),
                function: (capture) async {
                  final String currentBarcode =
                      capture.barcodes.first.rawValue ?? "";

                  final barcodes = capture.barcodes;
                  if (barcodes.isEmpty) return;

                  HapticFeedback.vibrate();
                  HapticFeedback.heavyImpact();
                  await _audioPlayer.stop();
                  _audioPlayer.play(_beepSource);

                  if (mounted) {
                    _searchQuery = currentBarcode;

                    final currentState = context.read<StockListBloc>().state;
                    FilterCriteria? currentFilters;
                    if (currentState is StockListLoaded) {
                      currentFilters = currentState.activeFilters;
                    }

                    context.read<StockListBloc>().add(
                      FetchFirstPageEvent(
                        query: _searchQuery,
                        filterColumn: "Barcode",
                        sortColumn: _dbFilterCol,
                        filters: currentFilters,
                      ),
                    );
                  }
                },
              )
            : const SizedBox(key: ValueKey('empty')),
      ),
    );
  }

  Widget _buildGlassSearchBar() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            border: Border.all(color: kGreyColor.withOpacity(0.6), width: 0.6),
            color: Colors.white.withOpacity(0.65),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: SearchFilterBar(
            onChanged: (value) {
              _searchQuery = value;
              _debouncer.run(() {
                final searchCol = _dbFilterCol == "quantity"
                    ? "description"
                    : _dbFilterCol;

                final currentState = context.read<StockListBloc>().state;
                FilterCriteria? currentFilters;
                if (currentState is StockListLoaded) {
                  currentFilters = currentState.activeFilters;
                }

                context.read<StockListBloc>().add(
                  FetchFirstPageEvent(
                    query: _searchQuery,
                    filterColumn: searchCol,
                    sortColumn: _dbFilterCol,
                    filters: currentFilters,
                  ),
                );
              });
            },
            onFilterTap: () {
              showDialog(
                context: context,
                builder: (_) => const StocklookupFilterDialog(),
              );
            },
            onScannerTap: () {
              FocusScope.of(context).unfocus();
              setState(() {
                isScanner = !isScanner;
              });

              if (!isScanner) {
                _searchQuery = "";
                final currentState = context.read<StockListBloc>().state;
                FilterCriteria? currentFilters;
                if (currentState is StockListLoaded) {
                  currentFilters = currentState.activeFilters;
                }

                context.read<StockListBloc>().add(
                  FetchFirstPageEvent(
                    query: "",
                    filterColumn: "Barcode",
                    sortColumn: _dbFilterCol,
                    filters: currentFilters,
                  ),
                );
              }
            },
          ),
        ),
      ),
    );
  }

  Widget itemsList() {
    return Expanded(
      child: BlocBuilder<StockListBloc, StockListState>(
        builder: (context, state) {
          if (state is StockListLoading) {
            return loadingWidget();
          }
          if (state is StockListLoaded) {
            if (state.stocks.isEmpty) return emptyOrErrorWidget();

            return AnimationLimiter(
              child: ListView.separated(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(
                  left: 15,
                  right: 15,
                  top: 0,
                  bottom: 100,
                ),
                itemCount: state.hasReachedMax
                    ? state.stocks.length
                    : state.stocks.length + 1,
                separatorBuilder: (ctx, i) => const SizedBox(height: 7),
                itemBuilder: (context, index) {
                  if (index >= state.stocks.length) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: CupertinoActivityIndicator(),
                      ),
                    );
                  }
                  return itemTile(state.stocks[index], index);
                },
              ),
            );
          }
          return emptyOrErrorWidget();
        },
      ),
    );
  }

  Widget emptyOrErrorWidget() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const BreathingStockLoader(),
        const Text(
          "Your stock(s) are not ready yet...",
          style: TextStyle(
            fontSize: 14,
            color: kPrimaryColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 110),
      ],
    );
  }

  Widget loadingWidget() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          "Getting Stocks From Database...",
          style: getSmartTitle(color: kThirdColor, fontSize: 16),
        ),
        Padding(
          padding: const EdgeInsets.only(
            top: 25,
            left: 80,
            right: 80,
            bottom: 5,
          ),
          child: ModernLoadingBar(),
        ),
        const Text(
          "This may take a few seconds.",
          style: TextStyle(fontSize: 11),
        ),
        const SizedBox(height: 60),
      ],
    );
  }

  Widget itemTile(StockVO stock, int index) {
    return RepaintBoundary(
      child: AnimationConfiguration.staggeredList(
        position: index,
        duration: const Duration(milliseconds: 500),
        child: ScaleAnimation(
          child: FadeInAnimation(
            child: GestureDetector(
              onTap: () {
                // context.read<FullImageBloc>().add(
                //   RequestFullImageEvent(
                //     stockId: stock.stockID,
                //     pictureFileName: stock.pictureFileName ?? "",
                //     forceRefresh: true
                //   ),
                // );

                context.navigateToNext(StockDetailsScreen(stock: stock));
              },
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // IMAGE
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Hero(
                          tag: 'stock_image_${stock.stockID}',
                          child: StockThumbnailTile(stock: stock),
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),

                    // TEXT COLUMN (Responsive Fix: Wrapped in Expanded)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Allow horizontal scrolling if text is extremely long,
                          // but constrained within the Expanded width.
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                Text(
                                  stock.description,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: getSmartTitle(
                                    color: kThirdColor,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            stock.barcode,
                            maxLines: 1, // Ensure no wrapping vertically
                            overflow: TextOverflow.ellipsis,
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

                    const SizedBox(width: 8), // Gap before quantity
                    // QUANTITY
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: stock.quantity > 0
                            ? Colors.blue.withOpacity(0.1)
                            : stock.quantity == 0
                            ? Colors.yellow.withOpacity(0.4)
                            : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        () {
                          String qtyString = (stock.quantity % 1 == 0)
                              ? stock.quantity.toInt().toString()
                              : double.parse(
                                  stock.quantity.toStringAsFixed(2),
                                ).toString();

                          if (qtyString.length > 7) {
                            return "${qtyString.substring(0, 7)}..";
                          }
                          return qtyString;
                        }(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: stock.quantity > 0
                              ? kPrimaryColor
                              : stock.quantity == 0
                              ? kThirdColor
                              : kErrorColor,
                          letterSpacing: -0.5,
                        ),
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
