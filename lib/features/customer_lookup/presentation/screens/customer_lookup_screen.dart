import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:intl/intl.dart';
import 'package:rmstock_scanner/entities/vos/customer_vo.dart';
import 'package:rmstock_scanner/entities/vos/search_mode.dart';
import 'package:rmstock_scanner/features/customer_lookup/presentation/BLoC/customer_lookup_bloc.dart';
import 'package:rmstock_scanner/features/customer_lookup/presentation/BLoC/customer_lookup_events.dart';
import 'package:rmstock_scanner/features/customer_lookup/presentation/BLoC/customer_lookup_states.dart';
import 'package:rmstock_scanner/features/customer_lookup/presentation/BLoC/customer_create_events.dart';
import 'package:rmstock_scanner/features/customer_lookup/presentation/screens/customer_details_screen.dart';
import 'package:rmstock_scanner/features/customer_lookup/presentation/widgets/customer_filter_chip_row.dart';
import 'package:rmstock_scanner/features/customer_lookup/presentation/widgets/customer_lookup_appbar.dart';
import 'package:rmstock_scanner/features/customer_lookup/presentation/widgets/customer_lookup_filter_dialog.dart';
import 'package:rmstock_scanner/features/customer_lookup/presentation/widgets/customer_lookup_scanner.dart';
import 'package:rmstock_scanner/features/customer_lookup/presentation/widgets/customer_search_filter.dart';
import 'package:rmstock_scanner/features/customer_lookup/presentation/widgets/customer_sync_info_widget.dart';
import 'package:rmstock_scanner/features/customer_lookup/presentation/widgets/customer_thumbnail_tile.dart';
import 'package:rmstock_scanner/features/customer_lookup/presentation/widgets/pending_customer_updates_tile.dart';
import 'package:rmstock_scanner/features/stock_lookup/presentation/widgets/breathing_stock_loader.dart';
import 'package:rmstock_scanner/utils/navigation_extension.dart';
import 'package:rmstock_scanner/utils/text_highlight_utils.dart';
import 'package:rmstock_scanner/features/customer_lookup/presentation/screens/customer_create_screen.dart';
import 'package:rmstock_scanner/features/customer_lookup/presentation/BLoC/customer_create_bloc.dart';

import '../../../../constants/colors.dart';
import '../../../../constants/theme_colors.dart';
import '../../../../constants/global_widgets.dart';
import '../../../../constants/txt_styles.dart';
import '../../../../entities/vos/filter_criteria.dart';

class Debouncer {
  final int milliseconds;
  Timer? _timer;

  Debouncer({required this.milliseconds});

  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }
}

class CustomerLookupScreen extends StatefulWidget {
  const CustomerLookupScreen({super.key});

  @override
  State<CustomerLookupScreen> createState() => _CustomerLookupScreenState();
}

class _CustomerLookupScreenState extends State<CustomerLookupScreen> {
  final ScrollController _scrollController = ScrollController();
  final Debouncer _debouncer = Debouncer(milliseconds: 500);

  String _selectedFilterChip = "Surname";
  String _dbFilterCol = "surname";
  String _searchQuery = "";
  static const String _searchColumn = "surname";
  SearchMode _searchMode = SearchMode.partial; // Default search mode

  bool isScanner = false;

  bool _isSyncInProgress() {
    return context.read<FetchCustomerBloc>().state is FetchCustomerProgress;
  }

  void _showSyncBlockedMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Customer sync in progress. Please wait."),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    context.read<CustomerListBloc>().add(FetchFirstCustomerPageEvent());
    context
        .read<CustomerFilterOptionsBloc>()
        .add(LoadCustomerFilterOptionsEvent());
    context.read<PendingCustomerUpdatesBloc>().add(
      LoadPendingCustomerUpdatesCountEvent(),
    );
  }

  void _onScroll() {
    if (_isBottom) {
      context.read<CustomerListBloc>().add(LoadMoreCustomersEvent());
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  String _mapChipToColumn(String label) {
    switch (label) {
      case "Surname":
        return "surname";
      case "Company":
        return "company";
      case "Email":
        return "email";
      case "Phone":
        return "phone";
      case "Suburb":
        return "suburb";
      case "State":
        return "state";
      default:
        return "surname";
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final bool isDark = colors.isDark;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: isDark ? colors.bg : kBgColor,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                const SizedBox(height: 25),
                const CustomerLookupAppbar(),
                const SizedBox(height: 5),
                const PendingCustomerUpdatesTile(),
               
                Divider(
                  indent: 15,
                  endIndent: 15,
                  thickness: 0.5,
                  color: isDark ? Colors.white38 : kGreyColor,
                ),
                const CustomerSyncInfoWidget(),
                BlocBuilder<CustomerListBloc, CustomerListState>(
                  builder: (context, state) {
                    final isAscending =
                        state is CustomerListLoaded ? state.isAscending : true;

                    if (state is CustomerListLoaded) {
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
                              child: CustomerFilterChipRow(
                                selectedFilter: _selectedFilterChip,
                                isAscending: isAscending,
                                onFilterChanged: (newLabel) {
                                  setState(() {
                                    _selectedFilterChip = newLabel;
                                    _dbFilterCol = _mapChipToColumn(newLabel);
                                  });

                                  final currentState =
                                      context.read<CustomerListBloc>().state;
                                  FilterCriteria? currentFilters;
                                  if (currentState is CustomerListLoaded) {
                                    currentFilters = currentState.activeFilters;
                                  }

                                  context.read<CustomerListBloc>().add(
                                    FetchFirstCustomerPageEvent(
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
                            const SizedBox(width: 8),
                            Text(
                              "${state.customers.length} of ${NumberFormat('#,###').format(state.totalCount)}",
                              style: TextStyle(
                                color: isDark ? Colors.white70 : colors.onSurfaceMuted,
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
                            child: CustomerFilterChipRow(
                              selectedFilter: _selectedFilterChip,
                              isAscending: isAscending,
                              onFilterChanged: (newLabel) {},
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '0 of 0',
                            style: TextStyle(
                              color: isDark ? Colors.white70 : colors.onSurfaceMuted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                scanner(),
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
                                context.appColors.surface.withOpacity(0.0),
                                context.appColors.surface.withOpacity(0.5),
                                context.appColors.surface.withOpacity(0.9),
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
            ? CustomerLookupScanner(
                key: const ValueKey('scanner'),
                function: (capture) async {
                  final barcodes = capture.barcodes;
                  if (barcodes.isEmpty) return;

                  final String currentBarcode =
                      barcodes.first.rawValue ?? '';

                  HapticFeedback.lightImpact();

                  if (mounted) {
                    _searchQuery = currentBarcode;

                    final currentState = context.read<CustomerListBloc>().state;
                    FilterCriteria? currentFilters;
                    if (currentState is CustomerListLoaded) {
                      currentFilters = currentState.activeFilters;
                    }

                    context.read<CustomerListBloc>().add(
                      FetchFirstCustomerPageEvent(
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

  Widget _buildGlassSearchBar() {
    final colors = context.appColors;
    final bool isDark = colors.isDark;
    final bool isTablet = MediaQuery.of(context).size.shortestSide >= 600;
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
            color: (isDark ? colors.surface : kSecondaryColor)
                .withOpacity(0.65),
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
            child: CustomerSearchFilterBar(
              searchMode: _searchMode,
              onSearchModeChanged: (newMode) {
                setState(() {
                  _searchMode = newMode;
                });
                
                // Re-trigger search with new mode if there's an active query
                if (_searchQuery.isNotEmpty) {
                  final currentState = context.read<CustomerListBloc>().state;
                  FilterCriteria? currentFilters;
                  if (currentState is CustomerListLoaded) {
                    currentFilters = currentState.activeFilters;
                  }

                  context.read<CustomerListBloc>().add(
                    FetchFirstCustomerPageEvent(
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
                  final currentState = context.read<CustomerListBloc>().state;
                  FilterCriteria? currentFilters;
                  if (currentState is CustomerListLoaded) {
                    currentFilters = currentState.activeFilters;
                  }

                  context.read<CustomerListBloc>().add(
                    FetchFirstCustomerPageEvent(
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
              onAddTap: () async {
                if (_isSyncInProgress()) {
                  _showSyncBlockedMessage();
                  return;
                }

                // Trigger customer sync before opening create screen
                context.read<FetchCustomerBloc>().add(
                  StartCustomerSyncEvent(ipAddress: ""),
                );

                // Wait for sync to complete
                await for (final state
                    in context.read<FetchCustomerBloc>().stream) {
                  if (state is! FetchCustomerProgress) {
                    break;
                  }
                }

                if (!mounted) return;

                context.read<CustomerCreateBloc>().add(ResetCustomerCreateEvent());
                final result = await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const CustomerCreateScreen(),
                  ),
                );

                if (result == true && mounted) {
                  // Refresh the customer list after successful creation
                  context.read<CustomerListBloc>().add(
                    FetchFirstCustomerPageEvent(
                      query: _searchQuery,
                      filterColumn: _searchColumn,
                      sortColumn: _dbFilterCol,
                      shouldToggleSort: false,
                      searchMode: _searchMode,
                    ),
                  );
                }
              },
              onFilterTap: () {
                if (_isSyncInProgress()) {
                  _showSyncBlockedMessage();
                  return;
                }

                showDialog(
                  context: context,
                  builder: (_) => const CustomerLookupFilterDialog(),
                );
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
                  _searchQuery = '';
                  final currentState = context.read<CustomerListBloc>().state;
                  FilterCriteria? currentFilters;
                  if (currentState is CustomerListLoaded) {
                    currentFilters = currentState.activeFilters;
                  }

                  context.read<CustomerListBloc>().add(
                    FetchFirstCustomerPageEvent(
                      query: '',
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
      child: BlocBuilder<CustomerListBloc, CustomerListState>(
        builder: (context, state) {
          final bool isTablet = MediaQuery.of(context).size.shortestSide >= 600;

          if (state is CustomerListLoading) {
            return loadingWidget();
          }

          if (state is CustomerListLoaded) {
            if (state.customers.isEmpty) {
              return emptyOrErrorWidget();
            }

            return AnimationLimiter(
              child: ListView.separated(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(left: 15, right: 15, top: 0, bottom: 100),
                itemCount: state.hasReachedMax
                    ? state.customers.length
                    : state.customers.length + 1,
                separatorBuilder: (ctx, i) => SizedBox(height: isTablet ? 10 : 7),
                itemBuilder: (context, index) {
                  if (index >= state.customers.length) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: CupertinoActivityIndicator(),
                      ),
                    );
                  }
                  final customer = state.customers[index];
                  final matchedField = state.matchedFields[customer.customerId];
                  return _buildCustomerTile(
                    customer,
                    index,
                    query: state.currentQuery,
                    matchedField: matchedField,
                  );
                },
              ),
            );
          }

          if (state is CustomerListError) {
            return errorWidget(state.message);
          }

          return emptyOrErrorWidget();
        },
      ),
    );
  }

  Widget emptyOrErrorWidget() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        BreathingStockLoader(
          centerChild: Center(
            child: Icon(
              Icons.people_alt_rounded,
              size: 70,
              color: kPrimaryColor,
            ),
          ),
        ),
        Text(
          'Your customers are not ready yet...',
          style: TextStyle(
            fontSize: 14,
            color: kPrimaryColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 110),
      ],
    );
  }

  Widget errorWidget(String message) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.error_outline, size: 56, color: kErrorColor),
        const SizedBox(height: 12),
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: kErrorColor,
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
          'Getting Customers From Database...',
          style: getSmartTitle(
            color: isDark ? Colors.white : colors.onSurface,
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
          'This may take a few seconds.',
          style: TextStyle(
            fontSize: 11,
            color: isDark ? Colors.white70 : colors.onSurfaceMuted,
          ),
        ),
        const SizedBox(height: 60),
      ],
    );
  }

  Widget _buildCustomerTile(
    CustomerVO customer,
    int index, {
    required String query,
    String? matchedField,
  }) {
    final colors = context.appColors;
    final bool isDark = colors.isDark;
    final double shortestSide = MediaQuery.of(context).size.shortestSide;
    final bool isTablet = shortestSide >= 600;
    final bool isLargeTablet = shortestSide >= 900;
    final double textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
    final double uiScale = isTablet
        ? (1.0 + ((textScale - 1.0) * 0.35)).clamp(1.0, 1.2)
        : 1.0;
    final double thumbnailSize = (isLargeTablet ? 52 : isTablet ? 44 : 36) * uiScale;
    final double tileHorizontalPadding = (isTablet ? 16 : 15) * uiScale;
    final double accountIconSize = (isLargeTablet ? 22 : isTablet ? 19 : 16) * uiScale;
    final double accountIconPadding = (isLargeTablet ? 9 : isTablet ? 7 : 6) * uiScale;

    // Determine which non-default fields to show (only if matched)
    final bool showCompany = matchedField == 'company' && customer.company.isNotEmpty;
    final bool showPhone = matchedField == 'phone' && customer.phone.isNotEmpty;
    final bool showFax = matchedField == 'fax' && customer.fax.isNotEmpty;
    final bool showMobile = matchedField == 'mobile' && customer.mobile.isNotEmpty;
    final bool showEmail = matchedField == 'email' && customer.email.isNotEmpty;
    final bool showExtraFields =
      showCompany || showPhone || showFax || showMobile || showEmail;
    final bool shouldScaleUp =
      isTablet && query.trim().isNotEmpty && matchedField != null;
    final double textUiScale = shouldScaleUp
      ? (1.0 + ((textScale - 1.0) * 0.85)).clamp(1.0, 1.65)
      : 1.0;
    final double tileVerticalPadding = (isTablet
        ? (shouldScaleUp || showExtraFields ? 18 : 10)
        : 8) *
      uiScale;

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
                context.navigateToNext(CustomerDetailsScreen(customer: customer));
              },
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? Color.lerp(colors.surface, Colors.white, 0.06)
                      : colors.surface,
                  borderRadius: const BorderRadius.all(Radius.circular(10)),
                  border: isDark
                      ? Border.all(color: Colors.white12)
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
                padding: EdgeInsets.symmetric(
                  horizontal: tileHorizontalPadding,
                  vertical: tileVerticalPadding,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: thumbnailSize,
                      height: thumbnailSize,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(isTablet ? 8 : 6),
                      ),
                      child: Hero(
                        tag: _customerHeroTag(customer),
                        flightShuttleBuilder: _buildCustomerHeroShuttle,
                        placeholderBuilder: (context, size, child) {
                          return SizedBox(
                            width: size.width,
                            height: size.height,
                            child: child,
                          );
                        },
                        child: ClipOval(
                          child: CustomerThumbnailTile(
                            customer: customer,
                            size: thumbnailSize,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: (isTablet ? 17 : 15) * uiScale),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Display name with highlighting
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                HighlightedText(
                                  text: customer.displayName,
                                  query: query,
                                  highlightColor: Colors.amber.withOpacity(0.6),
                                  style: getSmartTitle(
                                    color: isDark ? Colors.white : colors.onSurface,
                                    fontSize: 14 * textUiScale,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: isTablet ? 4 : 3),
                          // Barcode with highlighting
                          HighlightedText(
                            text: _barcodeLine(customer),
                            query: query,
                            highlightColor: Colors.amber.withOpacity(0.6),
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 13 * textUiScale,
                              color: kPrimaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          // Company (only if matched)
                          if (showCompany) ...[
                            SizedBox(height: isTablet ? 4 : 3),
                            Row(
                              children: [
                                Icon(
                                  Icons.business,
                                  size: 12 * textUiScale,
                                  color: isDark ? Colors.white70 : colors.onSurfaceMuted,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: HighlightedText(
                                    text: customer.company,
                                    query: query,
                                    highlightColor: Colors.amber.withOpacity(0.6),
                                    style: TextStyle(
                                      fontSize: 12 * textUiScale,
                                      color: isDark ? Colors.white70 : colors.onSurfaceMuted,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          // Phone (only if matched)
                          if (showPhone) ...[
                            SizedBox(height: isTablet ? 4 : 3),
                            Row(
                              children: [
                                Icon(
                                  Icons.phone,
                                  size: 12 * textUiScale,
                                  color: isDark ? Colors.white70 : colors.onSurfaceMuted,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: HighlightedText(
                                    text: customer.phone,
                                    query: query,
                                    highlightColor: Colors.amber.withOpacity(0.6),
                                    style: TextStyle(
                                      fontSize: 12 * textUiScale,
                                      color: isDark ? Colors.white70 : colors.onSurfaceMuted,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          // Fax (only if matched)
                          if (showFax) ...[
                            SizedBox(height: isTablet ? 4 : 3),
                            Row(
                              children: [
                                Icon(
                                  Icons.print,
                                  size: 12 * textUiScale,
                                  color: isDark ? Colors.white70 : colors.onSurfaceMuted,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: HighlightedText(
                                    text: customer.fax,
                                    query: query,
                                    highlightColor: Colors.amber.withOpacity(0.6),
                                    style: TextStyle(
                                      fontSize: 12 * textUiScale,
                                      color: isDark ? Colors.white70 : colors.onSurfaceMuted,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          // Mobile (only if matched)
                          if (showMobile) ...[
                            SizedBox(height: isTablet ? 4 : 3),
                            Row(
                              children: [
                                Icon(
                                  Icons.phone_android,
                                  size: 12 * textUiScale,
                                  color: isDark ? Colors.white70 : colors.onSurfaceMuted,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: HighlightedText(
                                    text: customer.mobile,
                                    query: query,
                                    highlightColor: Colors.amber.withOpacity(0.6),
                                    style: TextStyle(
                                      fontSize: 12 * textUiScale,
                                      color: isDark ? Colors.white70 : colors.onSurfaceMuted,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          // Email (only if matched)
                          if (showEmail) ...[
                            SizedBox(height: isTablet ? 4 : 3),
                            Row(
                              children: [
                                Icon(
                                  Icons.email,
                                  size: 12 * textUiScale,
                                  color: isDark ? Colors.white70 : colors.onSurfaceMuted,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: HighlightedText(
                                    text: customer.email,
                                    query: query,
                                    highlightColor: Colors.amber.withOpacity(0.6),
                                    style: TextStyle(
                                      fontSize: 12 * textUiScale,
                                      color: isDark ? Colors.white70 : colors.onSurfaceMuted,
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
                    const SizedBox(width: 8),
                    Container(
                      padding: EdgeInsets.all(accountIconPadding),
                      decoration: BoxDecoration(
                        color: (customer.account
                                ? Colors.green
                                : (isDark
                                    ? Colors.white70
                                    : Colors.blueGrey[700]!))
                            .withOpacity(0.12),
                        borderRadius: BorderRadius.circular(isTablet ? 10 : 8),
                      ),
                      child: Icon(
                        Icons.person,
                        color: customer.account
                            ? Colors.green
                            : (isDark
                                ? Colors.white70
                                : Colors.blueGrey[700]!),
                        size: accountIconSize,
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

  String _barcodeLine(CustomerVO customer) {
    if (customer.barcode.isNotEmpty) return customer.barcode;
    return '---';
  }

  String _customerHeroTag(CustomerVO customer) {
    return 'customer_avatar_${customer.customerId}';
  }

  Widget _buildCustomerHeroShuttle(
    BuildContext context,
    Animation<double> animation,
    HeroFlightDirection flightDirection,
    BuildContext fromHeroContext,
    BuildContext toHeroContext,
  ) {
    final Hero toHero = toHeroContext.widget as Hero;
    return FadeTransition(
      opacity: animation,
      child: Material(
        color: Colors.transparent,
        child: toHero.child,
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
