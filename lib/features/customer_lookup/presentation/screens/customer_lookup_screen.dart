import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:intl/intl.dart';
import 'package:rmmobile/entities/vos/customer_vo.dart';
import 'package:rmmobile/entities/vos/search_mode.dart';
import 'package:rmmobile/features/customer_lookup/presentation/BLoC/customer_lookup_bloc.dart';
import 'package:rmmobile/features/customer_lookup/presentation/BLoC/customer_lookup_events.dart';
import 'package:rmmobile/features/customer_lookup/presentation/BLoC/customer_lookup_states.dart';
import 'package:rmmobile/features/customer_lookup/presentation/BLoC/customer_create_events.dart';
import 'package:rmmobile/features/customer_lookup/presentation/screens/customer_details_screen.dart';
import 'package:rmmobile/features/customer_lookup/presentation/widgets/customer_filter_chip_row.dart';
import 'package:rmmobile/features/customer_lookup/presentation/widgets/customer_lookup_appbar.dart';
import 'package:rmmobile/features/customer_lookup/presentation/widgets/customer_lookup_filter_dialog.dart';
import 'package:rmmobile/features/customer_lookup/presentation/widgets/customer_lookup_scanner.dart';
import 'package:rmmobile/features/customer_lookup/presentation/widgets/customer_search_filter.dart';
import 'package:rmmobile/features/customer_lookup/presentation/widgets/customer_sync_info_widget.dart';
import 'package:rmmobile/features/customer_lookup/presentation/widgets/customer_thumbnail_tile.dart';
import 'package:rmmobile/features/customer_lookup/presentation/widgets/pending_customer_updates_tile.dart';
import 'package:rmmobile/features/stock_lookup/presentation/widgets/breathing_stock_loader.dart';
import 'package:rmmobile/utils/navigation_extension.dart';
import 'package:rmmobile/utils/text_highlight_utils.dart';
import 'package:rmmobile/features/customer_lookup/presentation/screens/customer_create_screen.dart';
import 'package:rmmobile/features/customer_lookup/presentation/BLoC/customer_create_bloc.dart';

import '../../../../constants/colors.dart';
import '../../../../constants/theme_colors.dart';
import '../../../../constants/global_widgets.dart';
import '../../../../constants/txt_styles.dart';
import '../../../../entities/vos/filter_criteria.dart';
import '../../../../utils/responsive_utils.dart';

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
  final bool showBackArrow;
  final bool selectionMode;
  final void Function(CustomerVO)? onCustomerSelected;
  
  const CustomerLookupScreen({
    super.key,
    this.showBackArrow = false,
    this.selectionMode = false,
    this.onCustomerSelected,
  });

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
    final bool useDesktopNav = context.useDesktopNav;
    final double horizontalPadding = useDesktopNav ? 10 : 15;
    final double topSpacer = useDesktopNav ? 15 : 25;
    
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: isDark ? colors.bg : kBgColor,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                SizedBox(height: topSpacer),
                CustomerLookupAppbar(showBackArrow: widget.showBackArrow),
                const SizedBox(height: 5),
                const PendingCustomerUpdatesTile(),
               
                Divider(
                  indent: horizontalPadding,
                  endIndent: horizontalPadding,
                  thickness: 0.5,
                  color: isDark ? Colors.white38 : kGreyColor,
                ),
                const CustomerSyncInfoWidget(),
                BlocBuilder<CustomerListBloc, CustomerListState>(
                  builder: (context, state) {
                    final isAscending =
                        state is CustomerListLoaded ? state.isAscending : true;

                    if (state is CustomerListLoaded) {
                      final int totalCount =
                          state.totalCount > 0 ? state.totalCount - 1 : 0;
                      final int loadedCount = state.customers
                          .where((c) => c.customerId != 0)
                          .length;
                      final int visibleCount = math.min(loadedCount, totalCount);
                      return Padding(
                        padding: EdgeInsets.only(
                          left: horizontalPadding,
                          right: horizontalPadding,
                          bottom: useDesktopNav ? 12 : 18,
                          top: useDesktopNav ? 6 : 10,
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
                              "$visibleCount of ${NumberFormat('#,###').format(totalCount)}",
                              style: TextStyle(
                                color: isDark ? Colors.white70 : colors.onSurfaceMuted,
                                fontSize: useDesktopNav ? 10 : 11,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return Padding(
                      padding: EdgeInsets.only(
                        left: horizontalPadding,
                        right: horizontalPadding,
                        bottom: useDesktopNav ? 12 : 18,
                        top: useDesktopNav ? 6 : 10,
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
                              fontSize: useDesktopNav ? 10 : 11,
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
                          height: useDesktopNav ? 80 : 100,
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
                      padding: EdgeInsets.only(
                        left: useDesktopNav ? 14 : 20,
                        right: useDesktopNav ? 14 : 20,
                        bottom: useDesktopNav ? 30 : 42,
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
    final bool isTablet = context.isTablet;
    final bool useDesktopNav = context.useDesktopNav;
    final double textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
    final double uiScale = isTablet
      ? (1.0 + ((textScale - 1.0) * 0.35)).clamp(1.0, 1.2)
      : 1.0;
    final double barHeight = useDesktopNav ? 44 : (isTablet ? 64 : 56) * uiScale;
    final double borderRadius = useDesktopNav ? 22 : 30;

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          height: barHeight,
          decoration: BoxDecoration(
            border: Border.all(
              color: isDark ? Colors.white38 : kGreyColor.withOpacity(0.6),
              width: 0.6,
            ),
            color: (isDark ? colors.surface : kSecondaryColor)
                .withOpacity(0.65),
            borderRadius: BorderRadius.circular(borderRadius),
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
          final bool isTablet = context.isTablet;
          final bool useDesktopNav = context.useDesktopNav;
          final double listHorizontalPadding = useDesktopNav ? 10 : 15;
          final double listBottomPadding = useDesktopNav ? 80 : 100;
          final double itemSeparator = useDesktopNav ? 5 : (isTablet ? 10 : 7);

          if (state is CustomerListLoading) {
            return loadingWidget();
          }

          if (state is CustomerListLoaded) {
            if (state.customers.isEmpty) {
              return emptyOrErrorWidget();
            }

            final String effectiveQuery = _searchQuery.isNotEmpty
                ? _searchQuery
                : state.currentQuery;

            return AnimationLimiter(
              child: ListView.separated(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.only(left: listHorizontalPadding, right: listHorizontalPadding, top: 0, bottom: listBottomPadding),
                itemCount: state.hasReachedMax
                    ? state.customers.length
                    : state.customers.length + 1,
                separatorBuilder: (ctx, i) => SizedBox(height: itemSeparator),
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
                    query: effectiveQuery,
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
          'Customer list is empty.',
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
    final bool isTablet = context.isTablet;
    final bool isLargeTablet = context.isLargeTablet;
    final bool useDesktopNav = context.useDesktopNav;
    final double textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
    final double uiScale = isTablet
        ? (1.0 + ((textScale - 1.0) * 0.35)).clamp(1.0, 1.2)
        : 1.0;
    final double thumbnailSize = useDesktopNav ? 32 : (isLargeTablet ? 52 : isTablet ? 44 : 36) * uiScale;
    final double tileHorizontalPadding = useDesktopNav ? 10 : (isTablet ? 16 : 15) * uiScale;
    final double accountIconSize = useDesktopNav ? 14 : (isLargeTablet ? 22 : isTablet ? 19 : 16) * uiScale;
    final double accountIconPadding = useDesktopNav ? 5 : (isLargeTablet ? 9 : isTablet ? 7 : 6) * uiScale;

    final String trimmedQuery = query.trim();
    final String lowerQuery = trimmedQuery.toLowerCase();
    final bool hasQuery = trimmedQuery.isNotEmpty;

    String normalizeValue(String value) {
      return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '');
    }

    bool matchesQuery(String value) {
      if (!hasQuery) return false;
      final normalized = value.trim();
      if (normalized.isEmpty) return false;
      if (normalized.toLowerCase().contains(lowerQuery)) return true;
      final compactQuery = normalizeValue(trimmedQuery);
      if (compactQuery.isEmpty) return false;
      return normalizeValue(normalized).contains(compactQuery);
    }

    final bool showCompany = matchesQuery(customer.company);
    final bool showPhone = matchesQuery(customer.phone);
    final bool showFax = matchesQuery(customer.fax);
    final bool showMobile = matchesQuery(customer.mobile);
    final bool showEmail = matchesQuery(customer.email);
    final bool showSuburb = matchesQuery(customer.suburb);
    final bool showState = matchesQuery(customer.state);
    final bool showPostcode = matchesQuery(customer.postcode);
    final bool showCountry = matchesQuery(customer.country);
    final bool showAddr1 = matchesQuery(customer.addr1);
    final bool showAddr2 = matchesQuery(customer.addr2);
    final bool showAddr3 = matchesQuery(customer.addr3);
    final bool showCustom1 = matchesQuery(customer.custom1);
    final bool showCustom2 = matchesQuery(customer.custom2);
    final bool showPosition = matchesQuery(customer.position);
    final bool showAbn = matchesQuery(customer.abn);
    final bool showExtraFields =
      showCompany ||
      showPhone ||
      showFax ||
      showMobile ||
      showEmail ||
      showSuburb ||
      showState ||
      showPostcode ||
      showCountry ||
      showAddr1 ||
      showAddr2 ||
      showAddr3 ||
      showCustom1 ||
      showCustom2 ||
      showPosition ||
      showAbn;
    final bool shouldScaleUp = isTablet && hasQuery;
    final double textUiScale = shouldScaleUp
      ? (1.0 + ((textScale - 1.0) * 0.85)).clamp(1.0, 1.65)
      : 1.0;
    final double tileVerticalPadding = useDesktopNav 
        ? 6 
        : (isTablet
            ? (shouldScaleUp || showExtraFields ? 18 : 10)
            : 8) *
          uiScale;

    final double titleFontSize = useDesktopNav ? 12 : (isTablet ? 15 : 14) * textUiScale;
    final double barcodeFontSize = useDesktopNav ? 11 : (isTablet ? 14 : 13) * textUiScale;
    final double infoLabelFontSize = useDesktopNav ? 10 : (isTablet ? 9.5 : 12) * textUiScale;
    final double infoValueFontSize = useDesktopNav ? 10 : (isTablet ? 14 : 12) * textUiScale;
    final double infoIconSize = useDesktopNav ? 10 : (isTablet ? 13 : 12) * textUiScale;
    final double tileBorderRadius = useDesktopNav ? 8 : 10;

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
                if (widget.selectionMode && widget.onCustomerSelected != null) {
                  // Selection mode: select customer and go back
                  widget.onCustomerSelected!(customer);
                  Navigator.of(context).pop();
                } else {
                  // Normal mode: go to details
                  context.navigateToNext(CustomerDetailsScreen(customer: customer));
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? Color.lerp(colors.surface, Colors.white, 0.06)
                      : colors.surface,
                  borderRadius: BorderRadius.all(Radius.circular(tileBorderRadius)),
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
                        borderRadius: BorderRadius.circular(useDesktopNav ? 5 : (isTablet ? 8 : 6)),
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
                    SizedBox(width: useDesktopNav ? 10 : (isTablet ? 17 : 15) * uiScale),
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
                                  query: trimmedQuery,
                                  highlightColor: Colors.amber.withOpacity(0.6),
                                  style: getSmartTitle(
                                    color: isDark ? Colors.white : colors.onSurface,
                                    fontSize: titleFontSize,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: useDesktopNav ? 2 : (isTablet ? 4 : 3)),
                          // Barcode with highlighting
                          HighlightedText(
                            text: _barcodeLine(customer),
                            query: trimmedQuery,
                            highlightColor: Colors.amber.withOpacity(0.6),
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: barcodeFontSize,
                              color: kPrimaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (showExtraFields) ..._buildMatchedInfoRows(
                            isTablet: isTablet,
                            isDark: isDark,
                            colors: colors,
                            labelFontSize: infoLabelFontSize,
                            valueFontSize: infoValueFontSize,
                            iconSize: infoIconSize,
                            query: query,
                            showCompany: showCompany,
                            company: customer.company,
                            showPhone: showPhone,
                            phone: customer.phone,
                            showFax: showFax,
                            fax: customer.fax,
                            showMobile: showMobile,
                            mobile: customer.mobile,
                            showEmail: showEmail,
                            email: customer.email,
                            showSuburb: showSuburb,
                            suburb: customer.suburb,
                            showState: showState,
                            state: customer.state,
                            showPostcode: showPostcode,
                            postcode: customer.postcode,
                            showCountry: showCountry,
                            country: customer.country,
                            showAddr1: showAddr1,
                            addr1: customer.addr1,
                            showAddr2: showAddr2,
                            addr2: customer.addr2,
                            showAddr3: showAddr3,
                            addr3: customer.addr3,
                            showCustom1: showCustom1,
                            custom1: customer.custom1,
                            showCustom2: showCustom2,
                            custom2: customer.custom2,
                            showPosition: showPosition,
                            position: customer.position,
                            showAbn: showAbn,
                            abn: customer.abn,
                          ),
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
                        borderRadius: BorderRadius.circular(useDesktopNav ? 6 : (isTablet ? 10 : 8)),
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
                    // Chevron arrow for selection mode - tapping goes to details
                    if (widget.selectionMode) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          if (_isSyncInProgress()) {
                            _showSyncBlockedMessage();
                            return;
                          }
                          context.navigateToNext(CustomerDetailsScreen(customer: customer));
                        },
                        child: Container(
                          padding: EdgeInsets.all(useDesktopNav ? 5 : (isTablet ? 8 : 6)),
                          decoration: BoxDecoration(
                            color: isDark 
                                ? Colors.white.withOpacity(0.1) 
                                : Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(useDesktopNav ? 6 : (isTablet ? 10 : 8)),
                          ),
                          child: Icon(
                            CupertinoIcons.chevron_right,
                            color: isDark ? Colors.white54 : Colors.grey[600],
                            size: useDesktopNav ? 14 : (isTablet ? 20 : 16),
                          ),
                        ),
                      ),
                    ],
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

  List<Widget> _buildMatchedInfoRows({
    required bool isTablet,
    required bool isDark,
    required AppThemeColors colors,
    required double labelFontSize,
    required double valueFontSize,
    required double iconSize,
    required String query,
    required bool showCompany,
    required String company,
    required bool showPhone,
    required String phone,
    required bool showFax,
    required String fax,
    required bool showMobile,
    required String mobile,
    required bool showEmail,
    required String email,
    required bool showSuburb,
    required String suburb,
    required bool showState,
    required String state,
    required bool showPostcode,
    required String postcode,
    required bool showCountry,
    required String country,
    required bool showAddr1,
    required String addr1,
    required bool showAddr2,
    required String addr2,
    required bool showAddr3,
    required String addr3,
    required bool showCustom1,
    required String custom1,
    required bool showCustom2,
    required String custom2,
    required bool showPosition,
    required String position,
    required bool showAbn,
    required String abn,
  }) {
    final rows = <Widget>[];
    void addRow(IconData icon, String label, String value) {
      if (rows.isNotEmpty) rows.add(SizedBox(height: isTablet ? 4 : 3));
      rows.add(
        _buildMatchedInfoRow(
          icon: icon,
          label: label,
          value: value,
          query: query.trim(),
          isDark: isDark,
          mutedColor: colors.onSurfaceMuted,
          labelFontSize: labelFontSize,
          valueFontSize: valueFontSize,
          iconSize: iconSize,
        ),
      );
    }

    if (showCompany) addRow(Icons.business, 'Company', company);
    if (showPosition) addRow(Icons.badge_outlined, 'Position', position);
    if (showPhone) addRow(Icons.phone, 'Phone', phone);
    if (showFax) addRow(Icons.print, 'Fax', fax);
    if (showMobile) addRow(Icons.phone_android, 'Mobile', mobile);
    if (showEmail) addRow(Icons.email, 'Email', email);
    if (showAddr1) addRow(Icons.location_on_outlined, 'Addr 1', addr1);
    if (showAddr2) addRow(Icons.location_on_outlined, 'Addr 2', addr2);
    if (showAddr3) addRow(Icons.location_on_outlined, 'Addr 3', addr3);
    if (showSuburb) addRow(Icons.location_city, 'Suburb', suburb);
    if (showState) addRow(Icons.map_outlined, 'State', state);
    if (showPostcode) addRow(Icons.markunread_mailbox_outlined, 'Postcode', postcode);
    if (showCountry) addRow(Icons.public, 'Country', country);
    if (showCustom1) addRow(Icons.tune, 'Custom 1', custom1);
    if (showCustom2) addRow(Icons.tune, 'Custom 2', custom2);
    if (showAbn) addRow(Icons.assignment_ind_outlined, 'ABN', abn);

    return rows;
  }

  Widget _buildMatchedInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required String query,
    required bool isDark,
    required Color mutedColor,
    required double labelFontSize,
    required double valueFontSize,
    required double iconSize,
  }) {
    final labelColor = isDark ? Colors.white70 : mutedColor;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: iconSize,
          color: labelColor,
        ),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: labelFontSize,
            color: labelColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        Expanded(
          child: HighlightedText(
            text: value,
            query: query.trim(),
            highlightColor: Colors.amber.withOpacity(0.6),
            style: TextStyle(
              fontSize: valueFontSize,
              color: labelColor,
            ),
          ),
        ),
      ],
    );
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
