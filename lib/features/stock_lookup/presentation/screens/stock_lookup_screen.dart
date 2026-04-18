import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:intl/intl.dart';
import 'package:rmmobile/entities/vos/search_mode.dart';
import 'package:rmmobile/entities/vos/stock_vo.dart';
import 'package:rmmobile/features/home_page/presentation/BLoC/home_screen_bloc.dart';
import 'package:rmmobile/features/home_page/presentation/BLoC/home_screen_states.dart';
import 'package:rmmobile/features/stock_lookup/presentation/BLoC/stock_lookup_states.dart';
import 'package:rmmobile/features/stock_lookup/presentation/screens/stock_details_screen.dart';
import 'package:rmmobile/features/stock_lookup/presentation/widgets/breathing_stock_loader.dart';
import 'package:rmmobile/features/stock_lookup/presentation/widgets/stock_thumbnail_tile.dart';
import 'package:rmmobile/utils/navigation_extension.dart';
import 'package:rmmobile/utils/text_highlight_utils.dart';
import '../../../../../../constants/colors.dart';
import '../../../../../../constants/theme_colors.dart';
import '../../../../constants/global_widgets.dart';
import '../../../../constants/txt_styles.dart';
import '../../../../entities/vos/filter_criteria.dart';
import '../../../../utils/responsive_utils.dart';
import '../BLoC/stock_lookup_bloc.dart';
import '../BLoC/stock_lookup_events.dart';
import '../widgets/filter_chip_row.dart';
import '../widgets/filter_tree_sidebar.dart';
import '../widgets/search_filter.dart';
import '../widgets/stock_lookup_appbar.dart';
import '../widgets/stock_lookup_scanner.dart';
import 'filter_screen.dart';
import '../widgets/sync_info_widget.dart';
import '../widgets/pending_stock_updates_tile.dart';

class Debouncer {
  final int milliseconds;
  Timer? _timer;

  Debouncer({required this.milliseconds});

  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }
}

/// View mode options for stock list (tablet only)
enum StockViewMode {
  list,
  gridMedium,
  largeIcons;

  String get displayName {
    switch (this) {
      case StockViewMode.list:
        return 'List';
      case StockViewMode.gridMedium:
        return 'Grid';
      case StockViewMode.largeIcons:
        return 'Large Icons';
    }
  }

  IconData get icon {
    switch (this) {
      case StockViewMode.list:
        return Icons.table_rows;
      case StockViewMode.gridMedium:
        return Icons.view_list;
      case StockViewMode.largeIcons:
        return Icons.grid_view;
    }
  }
}

class StockLookupScreen extends StatefulWidget {
  final bool showBackArrow;
  
  const StockLookupScreen({super.key, this.showBackArrow = false});

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
  static const String _searchColumn = "description";
  SearchMode _searchMode = SearchMode.partial; // Default search mode

  final AudioPlayer _audioPlayer = AudioPlayer()
    ..setReleaseMode(ReleaseMode.stop);

  final _beepSource = AssetSource('audio/beep.mp3');

  bool isScanner = false;

  // Tablet sidebar width (resizable)
  double _sidebarWidth = 280.0;
  static const double _minSidebarWidth = 200.0;
  static const double _maxSidebarWidth = 600.0;

  // View mode (tablet only)
  StockViewMode _viewMode = StockViewMode.list;

  bool _isSyncInProgress() {
    return context.read<FetchStockBloc>().state is FetchStockProgress;
  }

  void _showSyncBlockedMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Stock sync in progress. Please wait."),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Initial Load
    context.read<StockListBloc>().add(FetchFirstPageEvent());
    context.read<FilterOptionsBloc>().add(LoadFilterOptionsEvent());
    context.read<PendingStockUpdatesBloc>().add(
      LoadPendingStockUpdatesCountEvent(),
    );
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
    final colors = context.appColors;
    final bool isDark = colors.isDark;
    final bool isTablet = context.isTablet;
    final bool isPortrait = context.isPortrait;

    // Reset to list view when switching to portrait mode on tablets
    if (isTablet && isPortrait && _viewMode != StockViewMode.list) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _viewMode = StockViewMode.list;
          });
        }
      });
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: isDark ? colors.bg : kBgColor,
      body: SafeArea(
        child: isTablet
            ? _buildTabletLayout(colors, isDark, isPortrait)
            : _buildMobileLayout(colors, isDark),
      ),
    );
  }

  Widget _buildTabletLayout(
    AppThemeColors colors,
    bool isDark,
    bool isPortrait,
  ) {
    final screenSize = MediaQuery.of(context).size;
    // Medium tablets/iPads: shortestSide between 600-900px
    final bool isLargeTablet = context.isLargeTablet;

    // In landscape mode, limit max sidebar width to 35% of screen width
    final double maxAllowedWidth = isPortrait
        ? _maxSidebarWidth
        : screenSize.width * 0.35;
    final double effectiveMaxWidth = maxAllowedWidth.clamp(
      _minSidebarWidth,
      _maxSidebarWidth,
    );

    return Row(
      children: [
        // Left sidebar - File Explorer style (resizable on large tablets only)
        SizedBox(
          width: isLargeTablet
              ? _sidebarWidth.clamp(_minSidebarWidth, effectiveMaxWidth)
              : (isPortrait ? 220.0 : 280.0), // Narrower for medium tablets in portrait
          child: const FilterTreeSidebar(),
        ),

        // Resize handle (large tablets only)
        if (isLargeTablet)
          GestureDetector(
            onHorizontalDragUpdate: (details) {
              setState(() {
                _sidebarWidth += details.delta.dx;
                _sidebarWidth = _sidebarWidth.clamp(
                  _minSidebarWidth,
                  effectiveMaxWidth,
                );
              });
            },
            child: MouseRegion(
              cursor: SystemMouseCursors.resizeColumn,
              child: Container(
                width: 20,
                color: Colors.transparent,
                child: Center(
                  child: Container(
                    width: 5,
                    height: 50,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white24
                          : kGreyColor.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ),
          ),

        // Right side - Stock list
        Expanded(
          child: _buildMainContent(
            colors,
            isDark,
            isTablet: true,
            isPortrait: isPortrait,
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(AppThemeColors colors, bool isDark) {
    return _buildMainContent(
      colors,
      isDark,
      isTablet: false,
      isPortrait: false,
    );
  }

  Widget _buildMainContent(
    AppThemeColors colors,
    bool isDark, {
    required bool isTablet,
    required bool isPortrait,
  }) {
    return Stack(
      children: [
        Column(
          children: [
            const SizedBox(height: 25),
            StockLookupAppbar(showBackArrow: widget.showBackArrow),
            const SizedBox(height: 5),
            const PendingStockUpdatesTile(),
            Divider(
              indent: 15,
              endIndent: 15,
              thickness: 0.5,
              color: isDark ? Colors.white30 : kGreyColor,
            ),
            const SyncInfoWidget(), // Added const
            // Chip states and Count Text
            BlocBuilder<StockListBloc, StockListState>(
              builder: (context, state) {
                final isAscending = state is StockListLoaded
                    ? state.isAscending
                    : true;
                if (state is StockListLoaded) {
                  final int totalCount =
                      state.totalCount > 0 ? state.totalCount - 1 : 0;
                  final int loadedCount =
                      state.stocks.where((s) => s.stockID != 0).length;
                  final int visibleCount = math.min(loadedCount, totalCount);
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
                                  filterColumn: _searchColumn,
                                  sortColumn: _dbFilterCol,
                                  filters: currentFilters,
                                  shouldToggleSort: true,
                                  searchMode: _searchMode,
                                ),
                              );
                            },
                          ),
                        ),
                        // View mode dropdown (tablet landscape only)
                        if (isTablet && !isPortrait) ...[
                          const SizedBox(width: 12),
                          _buildViewModeDropdown(isDark),
                        ],
                        const SizedBox(width: 16),
                        Text(
                          "$visibleCount of ${NumberFormat('#,###').format(totalCount)}",
                          style: TextStyle(
                            color: isDark ? Colors.white70 : kGreyColor,
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
                        style: TextStyle(
                          color: isDark ? Colors.white70 : kGreyColor,
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
                            (isDark ? colors.surface : kSecondaryColor)
                                .withOpacity(0.0),
                            (isDark ? colors.surface : kSecondaryColor)
                                .withOpacity(0.5),
                            (isDark ? colors.surface : kSecondaryColor)
                                .withOpacity(0.9),
                          ],
                          stops: const [0.0, 0.4, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.only(
                    left: 15,
                    right: 15,
                    bottom: 42,
                  ),
                  child: _buildGlassSearchBar(),
                ),
              ],
            ),
          ),
        ),
      ],
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
                        filterColumn: _searchColumn,
                        sortColumn: _dbFilterCol,
                        filters: currentFilters,
                        shouldToggleSort: false,
                        searchMode: _searchMode,
                      ),
                    );
                  }
                },
              )
            : const SizedBox(key: ValueKey('empty')),
      ),
    );
  }

  Widget _buildViewModeDropdown(bool isDark) {
    final colors = context.appColors;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      decoration: BoxDecoration(
        color: isDark ? colors.surface.withOpacity(0.8) : kSecondaryColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? Colors.white24 : kGreyColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: StockViewMode.values.map((mode) {
          final isSelected = _viewMode == mode;
          return GestureDetector(
            onTap: () {
              setState(() {
                _viewMode = mode;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: isSelected
                    ? kPrimaryColor.withOpacity(0.2)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                mode.icon,
                size: 22,
                color: isSelected
                    ? kPrimaryColor
                    : (isDark ? Colors.white70 : kThirdColor),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildGlassSearchBar() {
    final colors = context.appColors;
    final bool isDark = colors.isDark;
    final bool isTablet = context.isTablet;
    final double textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
    final double uiScale = isTablet
        ? (1.0 + ((textScale - 1.0) * 0.35)).clamp(1.0, 1.2)
        : 1.0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          height: (isTablet ? 64 : 56) * uiScale,
          decoration: BoxDecoration(
            border: Border.all(
              color: isDark ? Colors.white38 : kGreyColor.withOpacity(0.6),
              width: 0.6,
            ),
            color: (isDark ? colors.surface : kSecondaryColor).withOpacity(
              0.65,
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? colors.cardShadow
                    : kThirdColor.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: SearchFilterBar(
            searchMode: _searchMode,
            onSearchFocus: () {
              if (isScanner) {
                setState(() => isScanner = false);
              }
            },
            onSearchModeChanged: (newMode) {
              setState(() {
                _searchMode = newMode;
              });

              // Re-trigger search with new mode if there's an active query
              if (_searchQuery.isNotEmpty) {
                final currentState = context.read<StockListBloc>().state;
                FilterCriteria? currentFilters;
                if (currentState is StockListLoaded) {
                  currentFilters = currentState.activeFilters;
                }

                context.read<StockListBloc>().add(
                  FetchFirstPageEvent(
                    query: _searchQuery,
                    filterColumn: _searchColumn,
                    sortColumn: _dbFilterCol,
                    filters: currentFilters,
                    shouldToggleSort: false,
                    searchMode: _searchMode,
                  ),
                );
              }
            },
            onChanged: (value) {
              _searchQuery = value;
              _debouncer.run(() {
                final currentState = context.read<StockListBloc>().state;
                FilterCriteria? currentFilters;
                if (currentState is StockListLoaded) {
                  currentFilters = currentState.activeFilters;
                }

                context.read<StockListBloc>().add(
                  FetchFirstPageEvent(
                    query: _searchQuery,
                    filterColumn: _searchColumn,
                    sortColumn: _dbFilterCol,
                    filters: currentFilters,
                    shouldToggleSort: false,
                    searchMode: _searchMode,
                  ),
                );
              });
            },
            onFilterTap: () {
              if (_isSyncInProgress()) {
                _showSyncBlockedMessage();
                return;
              }

              context.navigateToNext(const FilterScreen());
            },
            onScannerTap: () {
              if (_isSyncInProgress()) {
                _showSyncBlockedMessage();
                return;
              }

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
                    filterColumn: _searchColumn,
                    sortColumn: _dbFilterCol,
                    filters: currentFilters,
                    shouldToggleSort: false,
                    searchMode: _searchMode,
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
          final bool isTablet = context.isTablet;
          if (state is StockListLoading) {
            return loadingWidget();
          }
          if (state is StockListLoaded) {
            if (state.stocks.isEmpty) return emptyOrErrorWidget();

            // Use grid view for tablet non-list modes
            if (isTablet && _viewMode != StockViewMode.list) {
              return _buildGridView(state, isTablet);
            }

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
                separatorBuilder: (ctx, i) =>
                    SizedBox(height: isTablet ? 10 : 7),
                itemBuilder: (context, index) {
                  if (index >= state.stocks.length) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: CupertinoActivityIndicator(),
                      ),
                    );
                  }
                  final stock = state.stocks[index];
                  final matchedField =
                      state.matchedFields[stock.stockID.toInt()];
                  return itemTile(
                    stock,
                    index,
                    query: state.currentQuery,
                    matchedField: matchedField,
                  );
                },
              ),
            );
          }
          return emptyOrErrorWidget();
        },
      ),
    );
  }

  Widget _buildGridView(StockListLoaded state, bool isTablet) {
    final colors = context.appColors;
    final bool isDark = colors.isDark;
    final screenSize = MediaQuery.of(context).size;
    final bool isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final bool isMediumTablet = context.isMediumTablet;
    final bool isLargeTablet = context.isLargeTablet;

    // Calculate available width for the grid (accounting for sidebar in landscape)
    final double availableWidth = isLandscape
        ? screenSize.width -
              _sidebarWidth -
              20 -
              30 // sidebar + handle + padding
        : screenSize.width - 30; // just padding

    // Grid configuration based on view mode
    int crossAxisCount;
    double childAspectRatio;
    final bool hasSearchQuery = state.currentQuery.trim().isNotEmpty;

    switch (_viewMode) {
      case StockViewMode.gridMedium:
        // Keep 2 columns, but reduce tile height for medium tablets
        crossAxisCount = 2;
        // Calculate item width and set aspect ratio to prevent overflow
        final double itemWidth =
            (availableWidth - 12) / 2; // 12 is crossAxisSpacing
        // For horizontal tiles: width / height ratio
        // Medium tablets get smaller height (higher aspect ratio)
        final double minItemHeight = hasSearchQuery 
            ? (isMediumTablet ? 95.0 : 130.0) 
            : (isMediumTablet ? 70.0 : 100.0);
        childAspectRatio = (itemWidth / minItemHeight).clamp(2.0, 7.0);
        break;
      case StockViewMode.largeIcons:
        // Medium tablets get 5 columns, large tablets get 5 columns with shorter cards
        crossAxisCount = 5;
        childAspectRatio = isMediumTablet 
            ? (hasSearchQuery ? 0.70 : 0.85) 
            : (hasSearchQuery ? 0.58 : 0.75);
        break;
      default:
        crossAxisCount = 2;
        final double itemWidth = (availableWidth - 12) / 2;
        final double minItemHeight = hasSearchQuery 
            ? (isMediumTablet ? 95.0 : 130.0) 
            : (isMediumTablet ? 70.0 : 100.0);
        childAspectRatio = (itemWidth / minItemHeight).clamp(2.0, 7.0);
    }

    // For large tablets in largeIcons mode, use Wrap with flexible height cards
    if (isLargeTablet && _viewMode == StockViewMode.largeIcons) {
      const double spacing = 12;
      final double horizontalPadding = 30; // 15 left + 15 right
      final double totalSpacing = spacing * (crossAxisCount - 1);
      final double cardWidth =
          (availableWidth - horizontalPadding + 30 - totalSpacing) / crossAxisCount;

      return AnimationLimiter(
        child: Align(
          alignment: Alignment.topLeft,
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(
              left: 15,
              right: 15,
              top: 0,
              bottom: 100,
            ),
            child: Wrap(
              spacing: spacing,
              runSpacing: spacing,
              alignment: WrapAlignment.start,
              crossAxisAlignment: WrapCrossAlignment.start,
              children: [
                ...state.stocks.asMap().entries.map((entry) {
                  final index = entry.key;
                  final stock = entry.value;
                  return AnimationConfiguration.staggeredGrid(
                    position: index,
                    duration: const Duration(milliseconds: 400),
                    columnCount: crossAxisCount,
                    child: ScaleAnimation(
                      child: FadeInAnimation(
                        child: SizedBox(
                          width: cardWidth,
                          child: _buildGridTileFlexible(
                            stock,
                            index,
                            isDark,
                            colors,
                            state.currentQuery,
                            cardWidth,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
                // Loading indicator
                if (!state.hasReachedMax)
                  SizedBox(
                    width: cardWidth,
                    height: 60,
                    child: const Center(
                      child: CupertinoActivityIndicator(),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    return AnimationLimiter(
      child: GridView.builder(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(
          left: 15,
          right: 15,
          top: 0,
          bottom: 100,
        ),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: childAspectRatio,
        ),
        itemCount: state.hasReachedMax
            ? state.stocks.length
            : state.stocks.length + 1,
        itemBuilder: (context, index) {
          if (index >= state.stocks.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: CupertinoActivityIndicator(),
              ),
            );
          }
          final stock = state.stocks[index];
          if (_viewMode == StockViewMode.gridMedium) {
            return _buildHorizontalGridTile(
              stock,
              index,
              isDark,
              colors,
              state.currentQuery,
            );
          }
          return _buildGridTile(
            stock,
            index,
            isDark,
            colors,
            state.currentQuery,
          );
        },
      ),
    );
  }

  Widget _buildGridTile(
    StockVO stock,
    int index,
    bool isDark,
    AppThemeColors colors,
    String query,
  ) {
    final double textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
    final double uiScale = (1.0 + ((textScale - 1.0) * 0.35)).clamp(1.0, 1.2);
    final bool isLargeTablet = context.isLargeTablet;
    final String trimmedQuery = query.trim();
    final String lowerQuery = trimmedQuery.toLowerCase();
    final bool hasQuery = trimmedQuery.isNotEmpty;

    bool matchesQuery(String? value) {
      if (!hasQuery || value == null) return false;
      final normalized = value.trim();
      if (normalized.isEmpty) return false;
      return normalized.toLowerCase().contains(lowerQuery);
    }

    //final bool showCustom1 = matchesQuery(stock.custom1);
    final bool showCustom2 = matchesQuery(stock.custom2);

    // Base font sizes - large tablets use fixed sizes to match list view
    final double descFontSize = isLargeTablet
        ? 14
        : (_viewMode == StockViewMode.largeIcons ? 12.5 : 12) * uiScale;
    final double barcodeFontSize = isLargeTablet
        ? 13
        : (_viewMode == StockViewMode.largeIcons ? 12 : 13) * uiScale;
    final double customFontSize =
        (_viewMode == StockViewMode.largeIcons ? 11 : 10) * uiScale;

    return AnimationConfiguration.staggeredGrid(
      position: index,
      duration: const Duration(milliseconds: 400),
      columnCount: _viewMode == StockViewMode.largeIcons ? 5 : 4,
      child: ScaleAnimation(
        child: FadeInAnimation(
          child: GestureDetector(
            onTap: () {
              if (_isSyncInProgress()) {
                _showSyncBlockedMessage();
                return;
              }
              context.navigateToNext(StockDetailsScreen(stock: stock));
            },
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? Color.lerp(colors.surface, Colors.white, 0.06)
                    : kSecondaryColor,
                borderRadius: BorderRadius.circular(12),
                border: isDark
                    ? Border.all(color: Colors.white.withOpacity(0.18))
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withOpacity(0.35)
                        : kThirdColor.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Thumbnail
                  Expanded(
                    flex: 13,
                    child: Container(
                      width: double.infinity,
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.05)
                            : kBgColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Hero(
                          tag: 'stock_image_${stock.stockID}',
                          child: StockThumbnailTile(stock: stock),
                        ),
                      ),
                    ),
                  ),

                  // Info - scrollable when overflow
                  Expanded(
                    flex: 7,
                    child: Padding(
                      padding: const EdgeInsets.only(
                        left: 8,
                        right: 8,
                        bottom: 6,
                      ),
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            HighlightedText(
                              text: stock.description,
                              query: trimmedQuery,
                              highlightColor: Colors.amber.withOpacity(0.6),
                              style: TextStyle(
                                color: isDark ? Colors.white : kThirdColor,
                                fontSize: descFontSize,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              applyTextScaler: true,
                            ),
                            const SizedBox(height: 2),
                            // Barcode
                            HighlightedText(
                              text: stock.barcode,
                              query: trimmedQuery,
                              highlightColor: Colors.amber.withOpacity(0.6),
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: barcodeFontSize,
                                color: kPrimaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              applyTextScaler: true,
                            ),
                            // Sell Price for Large Icons
                            if (_viewMode == StockViewMode.largeIcons) ...[
                              const SizedBox(height: 2),
                              Text(
                                '\$${_formatSellPrice(stock)}',
                                style: TextStyle(
                                  fontSize: barcodeFontSize,
                                  color: Colors.green[700],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                            // Custom1 for Large Icons (always show if non-empty, highlight when matched)
                            if (_viewMode == StockViewMode.largeIcons &&
                                stock.custom1 != null &&
                                stock.custom1!.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              HighlightedText(
                                text: stock.custom1!,
                                query: trimmedQuery,
                                highlightColor: Colors.amber.withOpacity(0.6),
                                style: TextStyle(
                                  fontSize: customFontSize,
                                  color: isDark ? Colors.white70 : kGreyColor,
                                  fontStyle: FontStyle.italic,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                applyTextScaler: true,
                              ),
                            ],
                            // Custom2 for Large Icons (only when matched)
                            if (_viewMode == StockViewMode.largeIcons &&
                                showCustom2) ...[
                              const SizedBox(height: 2),
                              HighlightedText(
                                text: stock.custom2!,
                                query: trimmedQuery,
                                highlightColor: Colors.amber.withOpacity(0.6),
                                style: TextStyle(
                                  fontSize: customFontSize,
                                  color: isDark ? Colors.white70 : kGreyColor,
                                  fontStyle: FontStyle.italic,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                applyTextScaler: true,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Flexible height grid tile for large tablets (content-based height, shows up to custom1)
  Widget _buildGridTileFlexible(
    StockVO stock,
    int index,
    bool isDark,
    AppThemeColors colors,
    String query,
    double cardWidth,
  ) {
    final double textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
    final double uiScale = (1.0 + ((textScale - 1.0) * 0.35)).clamp(1.0, 1.2);
    final String trimmedQuery = query.trim();

    // Fixed font sizes for large tablets
    const double descFontSize = 14.0;
    const double barcodeFontSize = 13.0;
    final double customFontSize = 11 * uiScale;

    // Calculate thumbnail height based on card width (square-ish)
    final double thumbnailHeight = cardWidth - 16; // Account for margins

    return GestureDetector(
      onTap: () {
        if (_isSyncInProgress()) {
          _showSyncBlockedMessage();
          return;
        }
        context.navigateToNext(StockDetailsScreen(stock: stock));
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDark
              ? Color.lerp(colors.surface, Colors.white, 0.06)
              : kSecondaryColor,
          borderRadius: BorderRadius.circular(12),
          border: isDark
              ? Border.all(color: Colors.white.withOpacity(0.18))
              : null,
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.35)
                  : kThirdColor.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min, // Allow content-based height
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Thumbnail with fixed height based on card width
            Container(
              width: double.infinity,
              height: thumbnailHeight,
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.05)
                    : kBgColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Hero(
                  tag: 'stock_image_${stock.stockID}',
                  child: StockThumbnailTile(stock: stock),
                ),
              ),
            ),
            // Info - flexible height content
            Padding(
              padding: const EdgeInsets.only(left: 8, right: 8, bottom: 3),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Description
                  HighlightedText(
                    text: stock.description,
                    query: trimmedQuery,
                    highlightColor: Colors.amber.withOpacity(0.6),
                    style: TextStyle(
                      color: isDark ? Colors.white : kThirdColor,
                      fontSize: descFontSize,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    applyTextScaler: true,
                  ),
                  const SizedBox(height: 2),
                  // Barcode
                  HighlightedText(
                    text: stock.barcode,
                    query: trimmedQuery,
                    highlightColor: Colors.amber.withOpacity(0.6),
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: barcodeFontSize,
                      color: kPrimaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    applyTextScaler: true,
                  ),
                  const SizedBox(height: 2),
                  // Sell Price
                  Text(
                    '\$${_formatSellPrice(stock)}',
                    style: TextStyle(
                      fontSize: barcodeFontSize,
                      color: Colors.green[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  // Custom1 row - always reserve space for consistent card height
                  const SizedBox(height: 2),
                  (stock.custom1 != null && stock.custom1!.isNotEmpty)
                      ? HighlightedText(
                          text: stock.custom1!,
                          query: trimmedQuery,
                          highlightColor: Colors.amber.withOpacity(0.6),
                          style: TextStyle(
                            fontSize: customFontSize,
                            height: 1.0,
                            color: isDark ? Colors.white70 : kGreyColor,
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          applyTextScaler: true,
                        )
                      : Text(
                          ' ', // Invisible placeholder with identical style
                          style: TextStyle(
                            fontSize: customFontSize,
                            height: 1.0,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Horizontal grid tile for Grid view (2 columns, row layout)
  Widget _buildHorizontalGridTile(
    StockVO stock,
    int index,
    bool isDark,
    AppThemeColors colors,
    String query,
  ) {
    final double textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
    final double uiScale = (1.0 + ((textScale - 1.0) * 0.35)).clamp(1.0, 1.2);
    final bool isLargeTablet = context.isLargeTablet;
    final String trimmedQuery = query.trim();
    final String lowerQuery = trimmedQuery.toLowerCase();
    final bool hasQuery = trimmedQuery.isNotEmpty;
    final bool isMediumTablet = context.isMediumTablet;

    bool matchesQuery(String? value) {
      if (!hasQuery || value == null) return false;
      final normalized = value.trim();
      if (normalized.isEmpty) return false;
      return normalized.toLowerCase().contains(lowerQuery);
    }

    final bool showCustom1 = matchesQuery(stock.custom1);
    final bool showCustom2 = matchesQuery(stock.custom2);
    
    // Check if we have multiple search hits (custom fields shown in addition to desc/barcode)
    final bool hasMultipleHits = hasQuery && (showCustom1 || showCustom2);
    
    // Thumbnail width: larger in search mode to balance the layout
    final double thumbnailWidth = hasQuery
        ? (isMediumTablet ? 75 : 120)  // Larger in search mode
        : (isMediumTablet ? 60 : 100); // Normal mode

    // Large tablets use fixed sizes to match list view
    final double descFontSize = isLargeTablet ? 14 : 13 * uiScale;
    final double barcodeFontSize = isLargeTablet ? 13 : 13 * uiScale;
    final double customFontSize = 11 * uiScale;

    return AnimationConfiguration.staggeredGrid(
      position: index,
      duration: const Duration(milliseconds: 400),
      columnCount: 2,
      child: ScaleAnimation(
        child: FadeInAnimation(
          child: GestureDetector(
            onTap: () {
              if (_isSyncInProgress()) {
                _showSyncBlockedMessage();
                return;
              }
              context.navigateToNext(StockDetailsScreen(stock: stock));
            },
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? Color.lerp(colors.surface, Colors.white, 0.06)
                    : kSecondaryColor,
                borderRadius: BorderRadius.circular(12),
                border: isDark
                    ? Border.all(color: Colors.white.withOpacity(0.18))
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withOpacity(0.35)
                        : kThirdColor.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Thumbnail on the left - fixed width
                  Container(
                    width: thumbnailWidth,
                    height: double.infinity,
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.05) : kBgColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Hero(
                        tag: 'stock_image_${stock.stockID}',
                        child: StockThumbnailTile(stock: stock),
                      ),
                    ),
                  ),

                  // Description & Barcode on the right
                  Expanded(
                    child: ClipRect(
                      child: Padding(
                        padding: const EdgeInsets.only(
                          left: 6,
                          right: 10,
                          top: 8,
                          bottom: 8,
                        ),
                        child: Column(
                          mainAxisAlignment: hasMultipleHits 
                              ? MainAxisAlignment.spaceEvenly 
                              : MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.max,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Flexible(
                              child: HighlightedText(
                                text: stock.description,
                                query: trimmedQuery,
                                highlightColor: Colors.amber.withOpacity(0.6),
                                style: TextStyle(
                                  color: isDark ? Colors.white : kThirdColor,
                                  fontSize: descFontSize,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                applyTextScaler: true,
                              ),
                            ),
                            SizedBox(height: hasMultipleHits ? 2 : 3),
                            Flexible(
                              child: HighlightedText(
                                text: stock.barcode,
                                query: trimmedQuery,
                                highlightColor: Colors.amber.withOpacity(0.6),
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: barcodeFontSize,
                                  color: kPrimaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                applyTextScaler: true,
                              ),
                            ),
                            // Custom1 for Grid view (only when matched)
                            if (showCustom1) ...[
                              SizedBox(height: hasMultipleHits ? 1 : 2),
                              Flexible(
                                child: HighlightedText(
                                  text: stock.custom1!,
                                  query: trimmedQuery,
                                  highlightColor: Colors.amber.withOpacity(0.6),
                                  style: TextStyle(
                                    fontSize: customFontSize,
                                    color: isDark ? Colors.white70 : kGreyColor,
                                    fontStyle: FontStyle.italic,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  applyTextScaler: true,
                                ),
                              ),
                            ],
                            // Custom2 for Grid view (only when matched)
                            if (showCustom2) ...[
                              SizedBox(height: hasMultipleHits ? 1 : 2),
                              Flexible(
                                child: HighlightedText(
                                  text: stock.custom2!,
                                  query: trimmedQuery,
                                  highlightColor: Colors.amber.withOpacity(0.6),
                                  style: TextStyle(
                                    fontSize: customFontSize,
                                    color: isDark ? Colors.white70 : kGreyColor,
                                    fontStyle: FontStyle.italic,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  applyTextScaler: true,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatSellPrice(StockVO stock) {
    double sell = stock.sell;
    // Include GST if applicable
    if ((stock.salesTax ?? "") == "GST") {
      sell = stock.sell * 1.1;
    }
    return sell.toStringAsFixed(2);
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
    final colors = context.appColors;
    final bool isDark = colors.isDark;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          "Getting Stocks From Database...",
          style: getSmartTitle(
            color: isDark ? Colors.white : kThirdColor,
            fontSize: 16,
          ),
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
        Text(
          "This may take a few seconds.",
          style: TextStyle(
            fontSize: 11,
            color: isDark ? Colors.white70 : kGreyColor,
          ),
        ),
        const SizedBox(height: 60),
      ],
    );
  }

  Widget itemTile(
    StockVO stock,
    int index, {
    required String query,
    String? matchedField,
  }) {
    final colors = context.appColors;
    final bool isDark = colors.isDark;
    final bool isTablet = context.isTablet;
    final double textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
    final double uiScale = isTablet
        ? (1.0 + ((textScale - 1.0) * 0.35)).clamp(1.0, 1.2)
        : 1.0;
    final double thumbnailSize = (isTablet ? 44 : 36) * uiScale;
    final double tileHorizontalPadding = (isTablet ? 16 : 15) * uiScale;

    final String trimmedQuery = query.trim();
    final String lowerQuery = trimmedQuery.toLowerCase();
    final bool hasQuery = trimmedQuery.isNotEmpty;

    bool matchesQuery(String? value) {
      if (!hasQuery || value == null) return false;
      final normalized = value.trim();
      if (normalized.isEmpty) return false;
      return normalized.toLowerCase().contains(lowerQuery);
    }

    // Check if we should show custom fields
    final bool showCustom1 = matchesQuery(stock.custom1);
    final bool showCustom2 = matchesQuery(stock.custom2);
    final bool showExtraFields = showCustom1 || showCustom2;
    final bool shouldScaleUp = isTablet && hasQuery;
    final double textUiScale = shouldScaleUp
        ? (1.0 + ((textScale - 1.0) * 0.85)).clamp(1.0, 1.65)
        : 1.0;
    final double tileVerticalPadding =
        (isTablet ? (shouldScaleUp || showExtraFields ? 18 : 10) : 8) * uiScale;

    return RepaintBoundary(
      child: AnimationConfiguration.staggeredList(
        position: index,
        duration: const Duration(milliseconds: 500),
        child: ScaleAnimation(
          child: FadeInAnimation(
            child: GestureDetector(
              onTap: () {
                if (_isSyncInProgress()) {
                  _showSyncBlockedMessage();
                  return;
                }
                context.navigateToNext(StockDetailsScreen(stock: stock));
              },
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? Color.lerp(colors.surface, Colors.white, 0.06)
                      : kSecondaryColor,
                  borderRadius: const BorderRadius.all(Radius.circular(10)),
                  border: isDark
                      ? Border.all(color: Colors.white.withOpacity(0.18))
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? Colors.black.withOpacity(0.35)
                          : kThirdColor.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                      spreadRadius: 0,
                    ),
                  ],
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: tileHorizontalPadding,
                  vertical: tileVerticalPadding,
                ),
                margin: EdgeInsets.zero,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // IMAGE
                    Container(
                      width: thumbnailSize,
                      height: thumbnailSize,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(isTablet ? 8 : 6),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(isTablet ? 8 : 6),
                        child: Hero(
                          tag: 'stock_image_${stock.stockID}',
                          child: StockThumbnailTile(stock: stock),
                        ),
                      ),
                    ),
                    SizedBox(width: (isTablet ? 17 : 15) * uiScale),

                    // TEXT COLUMN (Responsive Fix: Wrapped in Expanded)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Description with highlighting
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                HighlightedText(
                                  text: stock.description,
                                  query: trimmedQuery,
                                  highlightColor: Colors.amber.withOpacity(0.6),
                                  style: getSmartTitle(
                                    color: isDark ? Colors.white : kThirdColor,
                                    fontSize: 14 * textUiScale,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: isTablet ? 4 : 3),
                          // Barcode with highlighting
                          HighlightedText(
                            text: stock.barcode,
                            query: trimmedQuery,
                            highlightColor: Colors.amber.withOpacity(0.6),
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 13 * textUiScale,
                              color: kPrimaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          // Custom1 field (only if matched)
                          if (showCustom1) ...[
                            SizedBox(height: isTablet ? 4 : 3),
                            Row(
                              children: [
                                Text(
                                  'Custom 1: ',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? Colors.white70 : kGreyColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Expanded(
                                  child: HighlightedText(
                                    text: stock.custom1!,
                                    query: trimmedQuery,
                                    highlightColor: Colors.amber.withOpacity(
                                      0.6,
                                    ),
                                    style: TextStyle(
                                      fontSize: 12 * textUiScale,
                                      color: isDark
                                          ? Colors.white70
                                          : kGreyColor,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          // Custom2 field (only if matched)
                          if (showCustom2) ...[
                            SizedBox(height: isTablet ? 4 : 3),
                            Row(
                              children: [
                                Text(
                                  'Custom 2: ',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? Colors.white70 : kGreyColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Expanded(
                                  child: HighlightedText(
                                    text: stock.custom2!,
                                    query: trimmedQuery,
                                    highlightColor: Colors.amber.withOpacity(
                                      0.6,
                                    ),
                                    style: TextStyle(
                                      fontSize: 12 * textUiScale,
                                      color: isDark
                                          ? Colors.white70
                                          : kGreyColor,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
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
                              ? (isDark ? colors.onSurface : kThirdColor)
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
