import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:intl/intl.dart';
import 'package:rmstock_scanner/entities/vos/customer_vo.dart';
import 'package:rmstock_scanner/features/customer_lookup/presentation/BLoC/customer_lookup_bloc.dart';
import 'package:rmstock_scanner/features/customer_lookup/presentation/BLoC/customer_lookup_events.dart';
import 'package:rmstock_scanner/features/customer_lookup/presentation/BLoC/customer_lookup_states.dart';
import 'package:rmstock_scanner/features/customer_lookup/presentation/screens/customer_details_screen.dart';
import 'package:rmstock_scanner/features/customer_lookup/presentation/widgets/customer_filter_chip_row.dart';
import 'package:rmstock_scanner/features/customer_lookup/presentation/widgets/customer_lookup_appbar.dart';
import 'package:rmstock_scanner/features/customer_lookup/presentation/widgets/customer_lookup_filter_dialog.dart';
import 'package:rmstock_scanner/features/customer_lookup/presentation/widgets/customer_lookup_scanner.dart';
import 'package:rmstock_scanner/features/customer_lookup/presentation/widgets/customer_search_filter.dart';
import 'package:rmstock_scanner/features/customer_lookup/presentation/widgets/customer_sync_info_widget.dart';
import 'package:rmstock_scanner/features/customer_lookup/presentation/widgets/customer_thumbnail_tile.dart';
import 'package:rmstock_scanner/features/stock_lookup/presentation/widgets/breathing_stock_loader.dart';
import 'package:rmstock_scanner/utils/navigation_extension.dart';

import '../../../../constants/colors.dart';
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
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: kBgColor,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                const SizedBox(height: 25),
                const CustomerLookupAppbar(),
                const SizedBox(height: 10),
                const Divider(
                  indent: 15,
                  endIndent: 15,
                  thickness: 0.5,
                  color: kGreyColor,
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
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "${state.customers.length} of ${NumberFormat('#,###').format(state.totalCount)}",
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
                            child: CustomerFilterChipRow(
                              selectedFilter: _selectedFilterChip,
                              isAscending: isAscending,
                              onFilterChanged: (newLabel) {},
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            '0 of 0',
                            style: TextStyle(color: kGreyColor, fontSize: 11),
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
            child: CustomerSearchFilterBar(
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
                    ),
                  );
                });
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
                  return _buildCustomerTile(state.customers[index], index);
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
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Getting Customers From Database...',
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
          'This may take a few seconds.',
          style: TextStyle(fontSize: 11),
        ),
        const SizedBox(height: 60),
      ],
    );
  }

  Widget _buildCustomerTile(CustomerVO customer, int index) {
    final bool isTablet = MediaQuery.of(context).size.shortestSide >= 600;
    final double textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
    final double uiScale = isTablet
        ? (1.0 + ((textScale - 1.0) * 0.35)).clamp(1.0, 1.2)
        : 1.0;
    final double thumbnailSize = (isTablet ? 44 : 36) * uiScale;
    final double tileVerticalPadding = (isTablet ? 10 : 8) * uiScale;
    final double tileHorizontalPadding = (isTablet ? 16 : 15) * uiScale;

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
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(isTablet ? 8 : 6),
                        child: CustomerThumbnailTile(customer: customer),
                      ),
                    ),
                    SizedBox(width: (isTablet ? 17 : 15) * uiScale),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                Text(
                                  customer.displayName,
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
                          SizedBox(height: isTablet ? 4 : 3),
                          Text(
                            _secondaryLine(customer),
                            maxLines: 1,
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
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: kPrimaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _stateLabel(customer),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: kPrimaryColor,
                          letterSpacing: -0.4,
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

  String _secondaryLine(CustomerVO customer) {
    if (customer.email.isNotEmpty) return customer.email;
    if (customer.phone.isNotEmpty) return customer.phone;
    if (customer.barcode.isNotEmpty) return customer.barcode;
    return '---';
  }

  String _stateLabel(CustomerVO customer) {
    if (customer.state.isNotEmpty) return customer.state;
    if (customer.suburb.isNotEmpty) return customer.suburb;
    return '--';
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
