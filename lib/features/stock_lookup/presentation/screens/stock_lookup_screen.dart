import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:rmstock_scanner/entities/vos/stock_vo.dart';
import 'package:rmstock_scanner/features/stock_lookup/presentation/BLoC/stock_lookup_states.dart';
import 'package:rmstock_scanner/features/stock_lookup/presentation/screens/stock_details_screen.dart';
import 'package:rmstock_scanner/utils/navigation_extension.dart';
import '../../../../../../constants/colors.dart';
import '../../../../constants/global_widgets.dart';
import '../../../../constants/images.dart';
import '../../../../constants/txt_styles.dart';
import '../BLoC/stock_lookup_bloc.dart';
import '../BLoC/stock_lookup_events.dart';
import '../widgets/filter_chip_row.dart';
import '../widgets/search_filter.dart';
import '../widgets/stock_lookup_appbar.dart';
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
      backgroundColor: kBgColor,
      body: SafeArea(
        child: Column(
          // shrinkWrap: true,
          // physics: const BouncingScrollPhysics(),
          children: [
            const SizedBox(height: 25),
            StockLookupAppbar(),
            const Divider(
              indent: 15,
              endIndent: 15,
              thickness: 0.8,
              color: kGreyColor,
              height: 40,
            ),
            SyncInfoWidget(),
            SearchFilterBar(
              onChanged: (value) {
                _searchQuery = value;
                _debouncer.run(() {
                  // Search using the currently selected chip (except Qty)
                  String searchCol = _dbFilterCol == "quantity"
                      ? "description"
                      : _dbFilterCol;
            
                  context.read<StockListBloc>().add(
                    FetchFirstPageEvent(
                      query: _searchQuery,
                      filterColumn: searchCol,
                      sortColumn: _dbFilterCol,
                    ),
                  );
                });
              },
              onFilterTap: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return const StocklookupFilterDialog();
                  },
                );
              },
            ),
            
            // Chip states and Count Text
            BlocBuilder<StockListBloc, StockListState>(
              builder: (context, state) {
                final isAscending = state is StockListLoaded
                    ? state.isAscending
                    : true;
                if (state is StockListLoaded) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 20,
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
            
                              // Search logic: If Qty selected, search disabled or defaults to Desc?
                              // Assuming search applies to currently selected sort column if possible
                              String searchCol = _dbFilterCol == "quantity"
                                  ? "description"
                                  : _dbFilterCol;
            
                              context.read<StockListBloc>().add(
                                FetchFirstPageEvent(
                                  query: _searchQuery,
                                  filterColumn:
                                      searchCol, // Search in this column
                                  sortColumn:
                                      _dbFilterCol, // Sort by this column
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "${state.stocks.length} of ${NumberFormat('#,###').format(state.totalCount)}",
                          style: TextStyle(color: kGreyColor, fontSize: 11),
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox();
              },
            ),
            
            //Item lists state
            itemsList(),
          ],
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
                padding: const EdgeInsets.symmetric(horizontal: 15),
                itemCount: state.hasReachedMax
                    ? state.stocks.length
                    : state.stocks.length + 1, // +1 for loading spinner
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
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 156,
          height: 156,
          child: Lottie.asset(
            "assets/animations/loading-stock.json",
            fit: BoxFit.fill,
          ),
        ),
        const SizedBox(height: 30),
        Text(
          "Your stocks are not ready yet...",
          style: getSmartTitle(color: kPrimaryColor, fontSize: 16),
        ),
        const SizedBox(height: 100),
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
        Text("This may take a few seconds.", style: TextStyle(fontSize: 11)),
        const SizedBox(height: 60),
      ],
    );
  }

  Widget itemTile(StockVO stock, int index) {
    return RepaintBoundary(
      // Optimizes rendering for long lists
      child: AnimationConfiguration.staggeredList(
        position: index,
        duration: const Duration(milliseconds: 650),

        child: ScaleAnimation(
          //verticalOffset: 50.0,
          child: FadeInAnimation(
            child: GestureDetector(
              onTap: () {
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
                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 50,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Hero(
                              tag: 'stock_image_${stock.stockID}',
                              child: CachedNetworkImage(
                                fit: BoxFit.fill,
                                imageUrl: stock.imageUrl ?? "",
                                placeholder: (_, url) => Image.asset(
                                  overviewPlaceholder,
                                  fit: BoxFit.fill,
                                ),
                                errorWidget: (_, url, error) => Image.asset(
                                  overviewPlaceholder,
                                  fit: BoxFit.fill,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: MediaQuery.of(context).size.width * 0.54,

                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    Text(
                                      stock.description ?? " - ",
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: getSmartTitle(
                                        color: kThirdColor,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              stock.barcode ?? " - ",
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 10,
                                color: Colors.blueGrey,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              "Custom1: ${stock.custom1 ?? " - "}",
                              style: getSmartTitle(
                                color: kPrimaryColor,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
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
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w900,
                          color: kPrimaryColor,

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
