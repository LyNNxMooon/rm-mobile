import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:get_it/get_it.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:alert_info/alert_info.dart';

import '../../../../constants/colors.dart';
import '../../../../constants/theme_colors.dart';
import '../../../../entities/vos/customer_vo.dart';
import '../../../../utils/global_var_utils.dart';
import '../../../../entities/vos/stock_vo.dart';
import '../../../../utils/navigation_extension.dart';
import '../../../stocktake/presentation/widgets/duplicate_stock_dialog.dart';
import '../../../../entities/vos/cart_item_vo.dart';
import '../BLoC/sales_bloc.dart';
import '../BLoC/sales_events.dart';
import '../BLoC/sales_states.dart';
import '../widgets/duplicate_customer_dialog.dart';
import '../widgets/finalise_sale_dialog.dart';
import '../widgets/sales_widgets.dart';
import '../models/delivery_info.dart';
import 'delivery_details_screen.dart';

final _sl = GetIt.instance;

class SalesScreen extends StatefulWidget {
  const SalesScreen({
    super.key,
    this.title = "Sales",
    this.themeColor = Colors.green,
    this.icon = Icons.point_of_sale_outlined,
  });

  final String title;
  final Color themeColor;
  final IconData icon;

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _discountController = TextEditingController(
    text: "0.00",
  );
  final FocusNode _searchFocusNode = FocusNode();

  // Scanner controller
  late MobileScannerController _scannerController;
  final AudioPlayer _audioPlayer = AudioPlayer()
    ..setReleaseMode(ReleaseMode.stop);
  final _beepSource = AssetSource('audio/beep.mp3');
  String? _lastScannedBarcode;
  DateTime? _lastScanTime;
  bool _isTorchOn = false;

  // BLoC for cart management
  late SalesBloc _salesBloc;

  // Selected customer
  CustomerVO? _selectedCustomer;

  // Delivery info (stored until user leaves screen)
  DeliveryInfo? _deliveryInfo;

  final bool _isPaymentMode = false;
  bool _showScanner = false;
  bool _showActions = false;
  bool _isIncTax = true;
  bool _isCompactView = false;
  bool _showTaxDetails = false;
  bool _showProfitDetails = false;
  String _selectedPaymentMethod = "Cash";
  String? _selectedOption;
  double _discountValue = 0.00;

  // Payment amounts for each payment type
  final Map<String, double> _paymentAmounts = {};

  // Survey and Comment values
  String _surveyValue = '';
  String _commentValue = '';
  final TextEditingController _surveyController = TextEditingController();

  late AnimationController _actionsAnimationController;
  late Animation<double> _actionsAnimation;

  final List<String> _optionItems = [
    "Add Survey",
    "Add Comment",
    "Add Delivery",
    "View Tax",
    "View Profit",
  ];

  final List<String> _paymentMethods = [
    "Cash",
    "EFTPOS",
    "Cheque",
    "Bank Card",
    "Master Card",
    "Visa",
    "Amex",
    "Diners",
    "Deposit",
  ];

  // Cart items from BLoC state
  List<CartItemVO> get _cartItems => _salesBloc.state.cartItems;

  double get _subtotal =>
      _cartItems.fold(0, (sum, item) => sum + item.extension);
  double get _discount => _discountValue;
  double get _rounding => 0.00; // Placeholder
  double get _total => _subtotal - _discount + _rounding;
  double get _totalPaid =>
      _paymentAmounts.values.fold(0.0, (sum, amount) => sum + amount);

  @override
  void initState() {
    super.initState();
    _salesBloc = _sl<SalesBloc>();
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      detectionTimeoutMs: 500,
      returnImage: false,
    );
    _actionsAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _actionsAnimation = CurvedAnimation(
      parent: _actionsAnimationController,
      curve: Curves.easeOutCubic,
    );
    // Close scanner when search field is focused
    _searchFocusNode.addListener(() {
      if (_searchFocusNode.hasFocus && _showScanner) {
        setState(() => _showScanner = false);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _discountController.dispose();
    _searchFocusNode.dispose();
    _actionsAnimationController.dispose();
    _scannerController.dispose();
    _audioPlayer.dispose();
    _salesBloc.close();
    super.dispose();
  }

  void _onBarcodeScanned(String barcode) async {
    // Debounce: prevent double processing of same frame
    final now = DateTime.now();
    if (_lastScanTime != null &&
        now.difference(_lastScanTime!).inMilliseconds < 1000 &&
        barcode == _lastScannedBarcode) {
      return;
    }
    _lastScanTime = now;
    _lastScannedBarcode = barcode;

    // Feedback
    HapticFeedback.vibrate();
    HapticFeedback.heavyImpact();
    await _audioPlayer.stop();
    _audioPlayer.play(_beepSource);

    // Search for stock
    _salesBloc.add(SearchStock(query: barcode));
  }

  String _buildCustomerDisplayName(CustomerVO customer) {
    final parts = <String>[];
    if (customer.givenNames.isNotEmpty) parts.add(customer.givenNames);
    if (customer.surname.isNotEmpty) parts.add(customer.surname);

    if (parts.isEmpty && customer.company.isNotEmpty) {
      return customer.company;
    }

    return parts.isEmpty ? "Unknown Customer" : parts.join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final bool isDark = colors.isDark;
    final bool isTablet = MediaQuery.of(context).size.shortestSide >= 600;

    return BlocProvider.value(
      value: _salesBloc,
      child: BlocListener<SalesBloc, SalesState>(
        listener: (context, state) async {
          if (state is StockDuplicatesFound) {
            // Show duplicate selection dialog
            final selected = await showDialog<StockVO>(
              context: context,
              builder: (_) => DuplicateStockDialog(matches: state.matches),
            );

            if (selected != null && mounted) {
              _salesBloc.add(SelectStock(stock: selected));
            } else {
              _salesBloc.add(ResetSearchState());
            }
          } else if (state is StockNotFound) {
            AlertInfo.show(
              context: context,
              text: state.message,
              typeInfo: TypeInfo.error,
              backgroundColor: isDark ? colors.surface : kSecondaryColor,
              iconColor: kErrorColor,
              textColor: kErrorColor,
              position: MessagePosition.top,
              padding: 70,
            );
          } else if (state is StockSearchError) {
            AlertInfo.show(
              context: context,
              text: state.error,
              typeInfo: TypeInfo.error,
              backgroundColor: isDark ? colors.surface : kSecondaryColor,
              iconColor: kErrorColor,
              textColor: kErrorColor,
              position: MessagePosition.top,
              padding: 70,
            );
          } else if (state is CartUpdated && state.message != null) {
            AlertInfo.show(
              context: context,
              text: state.message!,
              typeInfo: TypeInfo.success,
              backgroundColor: isDark ? colors.surface : kSecondaryColor,
              iconColor: kPrimaryColor,
              textColor: kPrimaryColor,
              position: MessagePosition.top,
              padding: 70,
            );
          } else if (state is CustomerDuplicatesFound) {
            // Show duplicate customer selection dialog
            final selected = await showDialog<CustomerVO>(
              context: context,
              builder: (_) => DuplicateCustomerDialog(matches: state.matches),
            );

            if (selected != null && mounted) {
              _salesBloc.add(SelectCustomer(customer: selected));
              setState(() => _selectedCustomer = selected);
            } else {
              _salesBloc.add(ResetSearchState());
            }
          } else if (state is CustomerSelected) {
            setState(() => _selectedCustomer = state.selectedCustomer);
            AlertInfo.show(
              context: context,
              text:
                  "Customer selected: ${state.selectedCustomer?.surname ?? ''}",
              typeInfo: TypeInfo.success,
              backgroundColor: isDark ? colors.surface : kSecondaryColor,
              iconColor: kPrimaryColor,
              textColor: kPrimaryColor,
              position: MessagePosition.top,
              padding: 70,
            );
          } else if (state is CustomerNotFound) {
            AlertInfo.show(
              context: context,
              text: state.message,
              typeInfo: TypeInfo.error,
              backgroundColor: isDark ? colors.surface : kSecondaryColor,
              iconColor: kErrorColor,
              textColor: kErrorColor,
              position: MessagePosition.top,
              padding: 70,
            );
          } else if (state is CustomerSearchError) {
            AlertInfo.show(
              context: context,
              text: state.error,
              typeInfo: TypeInfo.error,
              backgroundColor: isDark ? colors.surface : kSecondaryColor,
              iconColor: kErrorColor,
              textColor: kErrorColor,
              position: MessagePosition.top,
              padding: 70,
            );
          }
        },
        child: BlocBuilder<SalesBloc, SalesState>(
          builder: (context, state) {
            return Scaffold(
              backgroundColor: isDark ? colors.bg : kBgColor,
              appBar: _buildAppBar(colors, isDark),
              body: SafeArea(
                child: Column(
                  children: [
                    // Top Section: Customer, Staff, Date
                    SalesTopHeader(
                      isIncTax: _isIncTax,
                      onTaxModeChanged: (value) =>
                          setState(() => _isIncTax = value),
                      staffName:
                          AppGlobals.instance.staffName ?? "Unknown Staff",
                      hasCustomer: _selectedCustomer != null,
                      customerBarcode: _selectedCustomer?.barcode,
                      customerName: _selectedCustomer != null
                          ? _buildCustomerDisplayName(_selectedCustomer!)
                          : null,
                      onCustomerSearch: (query) {
                        _salesBloc.add(SearchCustomer(query: query));
                      },
                      onCustomerClear: () {
                        _salesBloc.add(ClearCustomer());
                        setState(() => _selectedCustomer = null);
                      },
                    ),

                    // Scanner Area (shown when scanner icon tapped)
                    if (_showScanner)
                      SalesScannerArea(
                        scannerController: _scannerController,
                        onBarcodeScanned: _onBarcodeScanned,
                      ),

                    // Middle Section: Cart Items
                    Expanded(child: _buildCartArea(colors, isDark, isTablet)),

                    // Search Bar (moved to bottom)
                    SalesSearchBar(
                      searchController: _searchController,
                      searchFocusNode: _searchFocusNode,
                      showScanner: _showScanner,
                      isTorchOn: _isTorchOn,
                      onScannerToggle: () {
                        setState(() {
                          _showScanner = !_showScanner;
                          if (_showScanner) {
                            _searchFocusNode.unfocus();
                          }
                        });
                      },
                      onTorchToggle: () {
                        setState(() {
                          _scannerController.toggleTorch();
                          _isTorchOn = !_isTorchOn;
                        });
                      },
                      onSearch: (query) {
                        _salesBloc.add(SearchStock(query: query));
                      },
                    ),

                    // Bottom Section: Summary, Payment & Commit
                    _buildBottomSummary(colors, isDark, isTablet),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(AppThemeColors colors, bool isDark) {
    return AppBar(
      elevation: 0,
      backgroundColor: widget.themeColor,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new,
          size: 20,
          color: Colors.white,
        ),
        onPressed: () => context.navigateBack(),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(widget.icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          Text(
            widget.title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 17,
            ),
          ),
        ],
      ),
      actions: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onSelected: (value) {
            if (value == 'default') {
              setState(() => _isCompactView = false);
            } else if (value == 'compact') {
              setState(() => _isCompactView = true);
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'default',
              child: Row(
                children: [
                  Icon(
                    _isCompactView
                        ? Icons.radio_button_off
                        : Icons.radio_button_checked,
                    size: 18,
                    color: _isCompactView ? Colors.grey : kPrimaryColor,
                  ),
                  const SizedBox(width: 8),
                  const Text('Default View'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'compact',
              child: Row(
                children: [
                  Icon(
                    _isCompactView
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    size: 18,
                    color: _isCompactView ? kPrimaryColor : Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  const Text('Compact View'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCartArea(AppThemeColors colors, bool isDark, bool isTablet) {
    if (_cartItems.isEmpty) {
      return LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.shopping_cart_outlined,
                      size: 60,
                      color: colors.onSurfaceMuted.withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Cart is empty",
                      style: TextStyle(
                        fontSize: 16,
                        color: colors.onSurfaceMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Scan an item to begin.",
                      style: TextStyle(
                        fontSize: 13,
                        color: colors.onSurfaceMuted.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }

    return Column(
      children: [
        // Optional Tablet Header Row mimicking the desktop grid (not shown in compact view)
        if (isTablet && !_isCompactView)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? colors.surface : Colors.grey.shade200,
              border: Border(
                bottom: BorderSide(
                  color: isDark ? Colors.white12 : Colors.grey.shade300,
                ),
              ),
            ),
            child: Row(
              children: [
                // Space for thumbnail
                const SizedBox(width: 40),
                Expanded(flex: 2, child: _buildGridHeader("Code", colors)),
                const SizedBox(width: 30),
                Expanded(
                  flex: 4,
                  child: _buildGridHeader("Description", colors),
                ),
                SizedBox(
                  width: 120,
                  child: _buildGridHeader("Price", colors, alignRight: true),
                ),
                SizedBox(
                  width: 140,
                  child: Center(child: _buildGridHeader("Qty", colors)),
                ),
                SizedBox(
                  width: 130,
                  child: _buildGridHeader("Ext", colors, alignRight: true),
                ),
              ],
            ),
          ),

        // Cart List
        Expanded(
          child: AnimationLimiter(
            child: ListView.separated(
              controller: _scrollController,
              padding: EdgeInsets.symmetric(
                horizontal: 10,
                vertical: _isCompactView ? 2 : 6,
              ),
              itemCount: _cartItems.length,
              separatorBuilder: (context, index) =>
                  SizedBox(height: _isCompactView ? 0 : 4),
              itemBuilder: (context, index) {
                final item = _cartItems[index];
                return AnimationConfiguration.staggeredList(
                  position: index,
                  duration: const Duration(milliseconds: 300),
                  child: SlideAnimation(
                    verticalOffset: 20.0,
                    child: FadeInAnimation(
                      child: _buildCartTileWithEditMode(
                        item,
                        index,
                        colors,
                        isDark,
                        isTablet,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGridHeader(
    String title,
    AppThemeColors colors, {
    bool alignRight = false,
  }) {
    return Text(
      title,
      textAlign: alignRight ? TextAlign.right : TextAlign.left,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: colors.onSurfaceMuted,
      ),
    );
  }

  /// Builds a cart tile based on edit mode state
  Widget _buildCartTileWithEditMode(
    CartItemVO item,
    int index,
    AppThemeColors colors,
    bool isDark,
    bool isTablet,
  ) {
    // If item is in edit mode, show expanded edit tile
    if (item.isEditing) {
      return ExpandedEditCartTile(
        item: item,
        index: index,
        colors: colors,
        isDark: isDark,
        isTablet: isTablet,
        isIncTax: _isIncTax,
        onQtyChanged: (qty) {
          _salesBloc.add(UpdateCartItemQty(index: index, qty: qty));
        },
        onPriceChanged: (price) {
          _salesBloc.add(UpdateCartItemPrice(index: index, price: price));
        },
        onSerialChanged: (serial) {
          _salesBloc.add(
            UpdateCartItemSerial(index: index, serialNumber: serial),
          );
        },
        onSave: () {
          _salesBloc.add(SaveCartItem(index: index));
        },
        onDelete: () {
          _salesBloc.add(RemoveCartItem(index: index));
        },
      );
    }

    // Otherwise show normal tile with slide-to-delete
    Widget tile;
    if (_isCompactView) {
      tile = _buildCompactCartTile(item, index, colors, isDark);
    } else if (isTablet) {
      tile = _buildTabletCartTile(item, index, colors, isDark);
    } else {
      tile = _buildMobileCartTile(item, index, colors, isDark);
    }

    // Wrap with slide-to-delete and tap to edit
    return DismissibleCartTile(
      isDark: isDark,
      colors: colors,
      onDelete: () {
        _salesBloc.add(RemoveCartItem(index: index));
      },
      child: GestureDetector(
        onTap: () {
          _salesBloc.add(EditCartItem(index: index));
        },
        child: tile,
      ),
    );
  }

  Widget _buildMobileCartTile(
    CartItemVO item,
    int index,
    AppThemeColors colors,
    bool isDark,
  ) {
    return MobileCartTile(
      item: item,
      index: index,
      colors: colors,
      isDark: isDark,
      isIncTax: _isIncTax,
    );
  }

  Widget _buildTabletCartTile(
    CartItemVO item,
    int index,
    AppThemeColors colors,
    bool isDark,
  ) {
    return TabletCartTile(
      item: item,
      index: index,
      colors: colors,
      isDark: isDark,
      isIncTax: _isIncTax,
    );
  }

  Widget _buildCompactCartTile(
    CartItemVO item,
    int index,
    AppThemeColors colors,
    bool isDark,
  ) {
    return CompactCartTile(
      item: item,
      index: index,
      colors: colors,
      isDark: isDark,
      isIncTax: _isIncTax,
    );
  }

  Widget _buildBottomSummary(
    AppThemeColors colors,
    bool isDark,
    bool isTablet,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2733) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Payment Methods Chips (only visible on Sales Screen)
              if (widget.title == "Sales") ...[
                SizedBox(
                  height: 34,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _paymentMethods.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 6),
                    itemBuilder: (context, index) {
                      final item = _paymentMethods[index];
                      final isSelected = _selectedPaymentMethod == item;
                      final hasAmount =
                          _paymentAmounts.containsKey(item) &&
                          _paymentAmounts[item]! > 0;
                      final amount = _paymentAmounts[item] ?? 0;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedPaymentMethod = item;
                          });
                          _showPaymentAmountDialog(
                            context,
                            item,
                            colors,
                            isDark,
                          );
                        },
                        onLongPress: hasAmount
                            ? () {
                                setState(() {
                                  _paymentAmounts.remove(item);
                                });
                              }
                            : null,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: hasAmount
                                ? kPrimaryColor
                                : (isSelected
                                      ? kPrimaryColor.withOpacity(0.3)
                                      : (isDark
                                            ? colors.surface
                                            : Colors.grey.shade100)),
                            borderRadius: BorderRadius.circular(17),
                            border: Border.all(
                              color: hasAmount || isSelected
                                  ? kPrimaryColor
                                  : (isDark
                                        ? Colors.white24
                                        : Colors.grey.shade300),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                item,
                                style: TextStyle(
                                  color: hasAmount
                                      ? Colors.white
                                      : (isSelected
                                            ? kPrimaryColor
                                            : (isDark
                                                  ? Colors.white70
                                                  : Colors.blueGrey.shade700)),
                                  fontWeight: hasAmount || isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  fontSize: 12,
                                ),
                              ),
                              if (hasAmount) ...[
                                const SizedBox(width: 4),
                                Text(
                                  "\$${amount.toStringAsFixed(0)}",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 10),
              ],

              // Totals Row
              IntrinsicHeight(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Actions Button and Profit breakdown (left column)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Profit breakdown display (above Actions button)
                        if (_showProfitDetails) ...[
                          _buildProfitBreakdown(colors, isDark),
                          const SizedBox(height: 8),
                        ],
                        // Actions Button
                        _buildActionsButton(colors, isDark, isTablet),
                      ],
                    ),

                    // Change/Remain amount display and Tax breakdown
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Change/Remain display
                          if (_totalPaid > _total)
                            Text(
                              "Change: \$${(_totalPaid - _total).toStringAsFixed(2)}",
                              style: const TextStyle(
                                color: Color(0xFF30B24C),
                                fontWeight: FontWeight.bold,
                                fontSize: 12.5,
                              ),
                            )
                          else if (_totalPaid > 0 && _totalPaid < _total)
                            Text(
                              "Remain: \$${(_total - _totalPaid).toStringAsFixed(2)}",
                              style: const TextStyle(
                                color: Colors.redAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 12.5,
                              ),
                            ),

                          // Tax breakdown display
                          if (_showTaxDetails) ...[
                            const SizedBox(height: 6),
                            _buildTaxBreakdown(colors, isDark),
                          ],
                        ],
                      ),
                    ),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "Subtotal: \$${_subtotal.toStringAsFixed(2)}",
                          style: TextStyle(
                            color: colors.onSurfaceMuted,
                            fontSize: isTablet ? 14 : 12.5,
                          ),
                        ),
                        SizedBox(height: isTablet ? 12 : 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: isTablet
                              ? CrossAxisAlignment.baseline
                              : CrossAxisAlignment.center,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              "Discount: \$",
                              style: TextStyle(
                                color: colors.onSurfaceMuted,
                                fontSize: isTablet ? 14 : 12.5,
                              ),
                            ),
                            SizedBox(
                              width: isTablet ? 120 : 55,
                              height: isTablet ? 56 : 20,
                              child: isTablet
                                  ? MediaQuery(
                                      data: MediaQuery.of(context).copyWith(
                                        textScaler: TextScaler.noScaling,
                                      ),
                                      child: TextField(
                                        controller: _discountController,
                                        keyboardType:
                                            const TextInputType.numberWithOptions(
                                              decimal: true,
                                            ),
                                        maxLines: 1,
                                        minLines: 1,
                                        textAlignVertical:
                                            TextAlignVertical.center,
                                        textAlign: TextAlign.right,
                                        style: TextStyle(
                                          color: isDark
                                              ? Colors.white
                                              : Colors.black87,
                                          fontSize: 18,
                                        ),
                                        decoration: InputDecoration(
                                          isDense: true,
                                          hintText: "0.00",
                                          hintStyle: TextStyle(
                                            color: colors.onSurfaceMuted,
                                            fontSize: 18,
                                          ),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 0,
                                              ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                            borderSide: BorderSide(
                                              color: isDark
                                                  ? Colors.white24
                                                  : Colors.grey.shade300,
                                            ),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                            borderSide: BorderSide(
                                              color: isDark
                                                  ? Colors.white24
                                                  : Colors.grey.shade300,
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                            borderSide: BorderSide(
                                              color: kPrimaryColor,
                                            ),
                                          ),
                                        ),
                                        onChanged: (value) {
                                          setState(() {
                                            _discountValue =
                                                double.tryParse(value) ?? 0.00;
                                          });
                                        },
                                      ),
                                    )
                                  : TextField(
                                      controller: _discountController,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                            decimal: true,
                                          ),
                                      maxLines: 1,
                                      minLines: 1,
                                      textAlign: TextAlign.right,
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black87,
                                        fontSize: 12.5,
                                      ),
                                      decoration: InputDecoration(
                                        isDense: true,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 4,
                                              vertical: 2,
                                            ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                          borderSide: BorderSide(
                                            color: isDark
                                                ? Colors.white24
                                                : Colors.grey.shade300,
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                          borderSide: BorderSide(
                                            color: isDark
                                                ? Colors.white24
                                                : Colors.grey.shade300,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                          borderSide: BorderSide(
                                            color: kPrimaryColor,
                                          ),
                                        ),
                                      ),
                                      onChanged: (value) {
                                        setState(() {
                                          _discountValue =
                                              double.tryParse(value) ?? 0.00;
                                        });
                                      },
                                    ),
                            ),
                          ],
                        ),
                        SizedBox(height: isTablet ? 0 : 6),
                        Text(
                          "Rounding: \$${_rounding.toStringAsFixed(2)}",
                          style: TextStyle(
                            color: colors.onSurfaceMuted,
                            fontSize: isTablet ? 14 : 12.5,
                          ),
                        ),
                        SizedBox(height: isTablet ? 4 : 2),
                        Text(
                          "\$${_total.toStringAsFixed(2)}",
                          style: TextStyle(
                            fontSize: isTablet ? 32 : 26,
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white : Colors.black87,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPaymentAmountDialog(
    BuildContext context,
    String paymentMethod,
    AppThemeColors colors,
    bool isDark,
  ) {
    final existingAmount = _paymentAmounts[paymentMethod] ?? 0.0;
    final controller = TextEditingController(
      text: existingAmount > 0 ? existingAmount.toStringAsFixed(2) : '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (dialogContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(dialogContext).viewInsets.bottom,
          ),
          child: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E2733) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.4 : 0.15),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "$paymentMethod Amount",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    if (existingAmount > 0)
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _paymentAmounts.remove(paymentMethod);
                          });
                          Navigator.of(dialogContext).pop();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            "Remove",
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller,
                        autofocus: true,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        decoration: InputDecoration(
                          prefixText: "\$ ",
                          prefixStyle: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                          hintText: "0.00",
                          hintStyle: TextStyle(
                            color: isDark
                                ? Colors.white30
                                : Colors.grey.shade400,
                          ),
                          filled: true,
                          fillColor: isDark
                              ? colors.surface
                              : Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 14,
                          ),
                        ),
                        onSubmitted: (value) {
                          final amount = double.tryParse(value) ?? 0.0;
                          if (amount > 0) {
                            setState(() {
                              _paymentAmounts[paymentMethod] = amount;
                            });
                          } else {
                            setState(() {
                              _paymentAmounts.remove(paymentMethod);
                            });
                          }
                          Navigator.of(dialogContext).pop();
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () {
                        final amount = double.tryParse(controller.text) ?? 0.0;
                        if (amount > 0) {
                          setState(() {
                            _paymentAmounts[paymentMethod] = amount;
                          });
                        } else {
                          setState(() {
                            _paymentAmounts.remove(paymentMethod);
                          });
                        }
                        Navigator.of(dialogContext).pop();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF30B24C), Color(0xFF60D394)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showFinaliseDialog() async {
    final result = await FinaliseSaleDialog.show(
      context: context,
      customer: _selectedCustomer,
    );

    if (result == null || result.result == FinaliseSaleResult.cancelled) {
      return;
    }

    // Handle the result
    if (result.result == FinaliseSaleResult.email) {
      final emailData = result.emailData;
      debugPrint('Sending receipt to: ${emailData?.email}');
    }

    // Clear everything for now
    _clearSale();

    if (mounted) {
      AlertInfo.show(
        padding: 80,
        context: context,
        text: "Committed to RM",
        typeInfo: TypeInfo.success,
      );
    }
  }

  void _clearSale() {
    setState(() {
      _salesBloc.add(ClearCart());
      _selectedCustomer = null;
      _deliveryInfo = null;
      _paymentAmounts.clear();
      _discountController.text = "0.00";
      _searchController.clear();
    });
  }

  Widget _buildSurveyMenuItem(
    BuildContext context,
    AppThemeColors colors,
    bool isDark,
    bool expanded,
    Function(bool) onExpandChanged,
  ) {
    final isTablet = MediaQuery.of(context).size.shortestSide >= 600;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 16 : 12,
        vertical: isTablet ? 14 : 10,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2733) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: expanded
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () {
                    onExpandChanged(false);
                  },
                  child: Row(
                    children: [
                      Icon(
                        Icons.poll_outlined,
                        size: isTablet ? 22 : 18,
                        color: kPrimaryColor,
                      ),
                      SizedBox(width: isTablet ? 16 : 12),
                      Text(
                        "Add Survey",
                        style: TextStyle(
                          color: isDark
                              ? Colors.white
                              : Colors.blueGrey.shade800,
                          fontWeight: FontWeight.w500,
                          fontSize: isTablet ? 15 : 13,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: isTablet ? 12 : 8),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: isTablet ? 48 : 32,
                        child: isTablet
                            ? MediaQuery(
                                data: MediaQuery.of(
                                  context,
                                ).copyWith(textScaler: TextScaler.noScaling),
                                child: TextField(
                                  controller: _surveyController,
                                  autofocus: true,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: isDark
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: "Survey code...",
                                    hintStyle: TextStyle(
                                      color: isDark
                                          ? Colors.white30
                                          : Colors.grey.shade400,
                                      fontSize: 16,
                                    ),
                                    filled: true,
                                    fillColor: isDark
                                        ? colors.surface
                                        : Colors.grey.shade100,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(6),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 0,
                                    ),
                                  ),
                                  onSubmitted: (value) {
                                    setState(() {
                                      _surveyValue = value.trim();
                                    });
                                    onExpandChanged(false);
                                  },
                                ),
                              )
                            : TextField(
                                controller: _surveyController,
                                autofocus: true,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                                decoration: InputDecoration(
                                  hintText: "Survey code...",
                                  hintStyle: TextStyle(
                                    color: isDark
                                        ? Colors.white30
                                        : Colors.grey.shade400,
                                    fontSize: 12,
                                  ),
                                  filled: true,
                                  fillColor: isDark
                                      ? colors.surface
                                      : Colors.grey.shade100,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(6),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                ),
                                onSubmitted: (value) {
                                  setState(() {
                                    _surveyValue = value.trim();
                                  });
                                  onExpandChanged(false);
                                },
                              ),
                      ),
                    ),
                    SizedBox(width: isTablet ? 12 : 8),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _surveyValue = _surveyController.text.trim();
                        });
                        onExpandChanged(false);
                      },
                      child: Container(
                        padding: EdgeInsets.all(isTablet ? 10 : 6),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF30B24C), Color(0xFF60D394)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          Icons.check,
                          color: Colors.white,
                          size: isTablet ? 20 : 16,
                        ),
                      ),
                    ),
                    if (_surveyValue.isNotEmpty) ...[
                      SizedBox(width: isTablet ? 8 : 4),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _surveyValue = '';
                            _surveyController.clear();
                          });
                          onExpandChanged(false);
                        },
                        child: Container(
                          padding: EdgeInsets.all(isTablet ? 10 : 6),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            Icons.close,
                            color: Colors.redAccent,
                            size: isTablet ? 20 : 16,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            )
          : GestureDetector(
              onTap: () {
                onExpandChanged(true);
              },
              child: Row(
                children: [
                  Icon(
                    Icons.poll_outlined,
                    size: isTablet ? 22 : 18,
                    color: kPrimaryColor,
                  ),
                  SizedBox(width: isTablet ? 16 : 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Add Survey",
                          style: TextStyle(
                            color: isDark
                                ? Colors.white
                                : Colors.blueGrey.shade800,
                            fontWeight: FontWeight.w500,
                            fontSize: isTablet ? 15 : 13,
                          ),
                        ),
                        if (_surveyValue.isNotEmpty) ...[
                          SizedBox(height: isTablet ? 4 : 2),
                          Text(
                            _surveyValue,
                            style: TextStyle(
                              color: kPrimaryColor,
                              fontWeight: FontWeight.w600,
                              fontSize: isTablet ? 13 : 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  void _showCommentDialog(
    BuildContext context,
    AppThemeColors colors,
    bool isDark,
  ) {
    final controller = TextEditingController(text: _commentValue);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (dialogContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(dialogContext).viewInsets.bottom,
          ),
          child: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E2733) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.4 : 0.15),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Add Comment",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    if (_commentValue.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _commentValue = '';
                          });
                          Navigator.of(dialogContext).pop();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            "Remove",
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  autofocus: true,
                  maxLines: 4,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  decoration: InputDecoration(
                    hintText: "Enter comment...",
                    hintStyle: TextStyle(
                      color: isDark ? Colors.white30 : Colors.grey.shade400,
                    ),
                    filled: true,
                    fillColor: isDark ? colors.surface : Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _commentValue = controller.text.trim();
                      });
                      Navigator.of(dialogContext).pop();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF30B24C), Color(0xFF60D394)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        "Save",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showActionsMenu(
    BuildContext context,
    AppThemeColors colors,
    bool isDark,
  ) {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay =
        Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;
    final buttonPosition = button.localToGlobal(Offset.zero, ancestor: overlay);

    bool surveyExpanded = false;
    _surveyController.text = _surveyValue;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Actions Menu",
      barrierColor: Colors.black12,
      transitionDuration: const Duration(milliseconds: 550),
      pageBuilder: (context, animation, secondaryAnimation) {
        return const SizedBox.shrink();
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInQuart,
        );

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Stack(
              children: [
                Positioned(
                  left: 12,
                  bottom:
                      MediaQuery.of(context).size.height -
                      buttonPosition.dy +
                      8,
                  child: Material(
                    color: Colors.transparent,
                    child: SizedBox(
                      width: MediaQuery.of(context).size.shortestSide >= 600
                          ? 280
                          : 220,
                      child: AnimatedBuilder(
                        animation: curvedAnimation,
                        builder: (context, child) {
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              ..._optionItems.reversed
                                  .toList()
                                  .asMap()
                                  .entries
                                  .map((entry) {
                                    final reverseIndex = entry.key;
                                    final index =
                                        _optionItems.length - 1 - reverseIndex;
                                    final item = entry.value;
                                    final isFirst = index == 0;

                                    // Stagger the reveal: bottom items appear first, slower rollout
                                    final staggerFactor =
                                        _optionItems.length + 3;
                                    final itemProgress =
                                        ((curvedAnimation.value *
                                                    staggerFactor) -
                                                reverseIndex)
                                            .clamp(0.0, 1.0);

                                    return ClipRect(
                                      child: Align(
                                        alignment: Alignment.bottomCenter,
                                        heightFactor: itemProgress,
                                        child: Opacity(
                                          opacity: itemProgress,
                                          child: Padding(
                                            padding: EdgeInsets.only(
                                              left: 0,
                                              right: 40,
                                              top: isFirst ? 8 : 4,
                                              bottom:
                                                  index ==
                                                      _optionItems.length - 1
                                                  ? 8
                                                  : 4,
                                            ),
                                            child: item == "Add Survey"
                                                ? _buildSurveyMenuItem(
                                                    context,
                                                    colors,
                                                    isDark,
                                                    surveyExpanded,
                                                    (expanded) {
                                                      setDialogState(() {
                                                        surveyExpanded =
                                                            expanded;
                                                      });
                                                    },
                                                  )
                                                : InkWell(
                                                    onTap: () {
                                                      if (item ==
                                                          "Add Comment") {
                                                        Navigator.of(
                                                          context,
                                                        ).pop();
                                                        // Use a microtask to show dialog after pop completes
                                                        Future.microtask(() {
                                                          if (mounted) {
                                                            _showCommentDialog(
                                                              this.context,
                                                              colors,
                                                              isDark,
                                                            );
                                                          }
                                                        });
                                                      } else if (item ==
                                                          "Add Delivery") {
                                                        Navigator.of(
                                                          context,
                                                        ).pop();
                                                        setState(() {
                                                          _showActions = false;
                                                          _actionsAnimationController
                                                              .reverse();
                                                        });
                                                        // Check if customer is selected
                                                        if (_selectedCustomer ==
                                                            null) {
                                                          Future.microtask(() {
                                                            if (mounted) {
                                                              AlertInfo.show(
                                                                context: this
                                                                    .context,
                                                                text:
                                                                    "Please select a customer before adding delivery details",
                                                                typeInfo:
                                                                    TypeInfo
                                                                        .warning,
                                                                backgroundColor:
                                                                    isDark
                                                                    ? colors
                                                                          .surface
                                                                    : kSecondaryColor,
                                                                iconColor:
                                                                    Colors
                                                                        .orange,
                                                                textColor:
                                                                    Colors
                                                                        .orange,
                                                                position:
                                                                    MessagePosition
                                                                        .top,
                                                                padding: 70,
                                                              );
                                                            }
                                                          });
                                                          return;
                                                        }
                                                        // Navigate to Delivery Details screen
                                                        Future.microtask(() async {
                                                          if (mounted) {
                                                            final result =
                                                                await Navigator.of(
                                                                  this.context,
                                                                ).push<
                                                                  DeliveryInfo
                                                                >(
                                                                  MaterialPageRoute(
                                                                    builder: (ctx) => DeliveryDetailsScreen(
                                                                      initialCustomer:
                                                                          _selectedCustomer,
                                                                      existingDelivery:
                                                                          _deliveryInfo,
                                                                    ),
                                                                  ),
                                                                );
                                                            if (result !=
                                                                    null &&
                                                                mounted) {
                                                              setState(
                                                                () =>
                                                                    _deliveryInfo =
                                                                        result,
                                                              );
                                                            }
                                                          }
                                                        });
                                                      } else if (item ==
                                                          "View Tax") {
                                                        Navigator.of(
                                                          context,
                                                        ).pop();
                                                        setState(() {
                                                          _showTaxDetails =
                                                              !_showTaxDetails;
                                                          _showActions = false;
                                                          _actionsAnimationController
                                                              .reverse();
                                                        });
                                                      } else if (item ==
                                                          "View Profit") {
                                                        Navigator.of(
                                                          context,
                                                        ).pop();
                                                        setState(() {
                                                          _showProfitDetails =
                                                              !_showProfitDetails;
                                                          _showActions = false;
                                                          _actionsAnimationController
                                                              .reverse();
                                                        });
                                                      } else {
                                                        Navigator.of(
                                                          context,
                                                        ).pop();
                                                        setState(() {
                                                          _selectedOption =
                                                              item;
                                                          _showActions = false;
                                                          _actionsAnimationController
                                                              .reverse();
                                                        });
                                                      }
                                                    },
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          10,
                                                        ),
                                                    child: Container(
                                                      padding: EdgeInsets.symmetric(
                                                        horizontal:
                                                            MediaQuery.of(
                                                                      context,
                                                                    )
                                                                    .size
                                                                    .shortestSide >=
                                                                600
                                                            ? 16
                                                            : 12,
                                                        vertical:
                                                            MediaQuery.of(
                                                                      context,
                                                                    )
                                                                    .size
                                                                    .shortestSide >=
                                                                600
                                                            ? 14
                                                            : 10,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: isDark
                                                            ? const Color(
                                                                0xFF1E2733,
                                                              )
                                                            : Colors.white,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              10,
                                                            ),
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: Colors.black
                                                                .withOpacity(
                                                                  isDark
                                                                      ? 0.3
                                                                      : 0.1,
                                                                ),
                                                            blurRadius: 8,
                                                            offset:
                                                                const Offset(
                                                                  0,
                                                                  2,
                                                                ),
                                                          ),
                                                        ],
                                                      ),
                                                      child: Row(
                                                        children: [
                                                          Icon(
                                                            _getActionIcon(
                                                              item,
                                                            ),
                                                            size:
                                                                MediaQuery.of(
                                                                      context,
                                                                    ).size.shortestSide >=
                                                                    600
                                                                ? 22
                                                                : 18,
                                                            color:
                                                                kPrimaryColor,
                                                          ),
                                                          SizedBox(
                                                            width:
                                                                MediaQuery.of(
                                                                      context,
                                                                    ).size.shortestSide >=
                                                                    600
                                                                ? 16
                                                                : 12,
                                                          ),
                                                          Expanded(
                                                            child: Text(
                                                              item,
                                                              style: TextStyle(
                                                                color: isDark
                                                                    ? Colors
                                                                          .white
                                                                    : Colors
                                                                          .blueGrey
                                                                          .shade800,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                                fontSize:
                                                                    MediaQuery.of(
                                                                          context,
                                                                        ).size.shortestSide >=
                                                                        600
                                                                    ? 15
                                                                    : 13,
                                                              ),
                                                            ),
                                                          ),
                                                          // Arrow icon for Comment when has value
                                                          if (item ==
                                                                  "Add Comment" &&
                                                              _commentValue
                                                                  .isNotEmpty)
                                                            Icon(
                                                              Icons
                                                                  .arrow_forward_ios,
                                                              size:
                                                                  MediaQuery.of(
                                                                        context,
                                                                      ).size.shortestSide >=
                                                                      600
                                                                  ? 16
                                                                  : 14,
                                                              color:
                                                                  kPrimaryColor,
                                                            ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                          ),
                                        ),
                                      ),
                                    );
                                  })
                                  .toList()
                                  .reversed,
                              // Finalise button - appears at bottom, animated last
                              Builder(
                                builder: (context) {
                                  final isTablet =
                                      MediaQuery.of(
                                        context,
                                      ).size.shortestSide >=
                                      600;
                                  final finaliseProgress =
                                      ((curvedAnimation.value *
                                                  (_optionItems.length + 4)) -
                                              _optionItems.length)
                                          .clamp(0.0, 1.0);
                                  return ClipRect(
                                    child: Align(
                                      alignment: Alignment.bottomCenter,
                                      heightFactor: finaliseProgress,
                                      child: Opacity(
                                        opacity: finaliseProgress,
                                        child: Padding(
                                          padding: const EdgeInsets.only(
                                            left: 0,
                                            right: 0,
                                            top: 4,
                                            bottom: 8,
                                          ),
                                          child: InkWell(
                                            onTap: () {
                                              Navigator.of(context).pop();
                                              setState(() {
                                                _showActions = false;
                                                _actionsAnimationController
                                                    .reverse();
                                              });
                                              _showFinaliseDialog();
                                            },
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            child: Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 20,
                                                vertical: isTablet ? 14 : 10,
                                              ),
                                              decoration: BoxDecoration(
                                                gradient: const LinearGradient(
                                                  colors: [
                                                    Color(0xFF30B24C),
                                                    Color(0xFF60D394),
                                                  ],
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: const Color(
                                                      0xFF30B24C,
                                                    ).withOpacity(0.4),
                                                    blurRadius: 10,
                                                    offset: const Offset(0, 3),
                                                  ),
                                                ],
                                              ),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  const Icon(
                                                    Icons.check_circle_outline,
                                                    size: 22,
                                                    color: Colors.white,
                                                  ),
                                                  const SizedBox(width: 12),
                                                  const Text(
                                                    "Finalise",
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 16,
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
                                },
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      if (mounted) {
        setState(() {
          _showActions = false;
          _actionsAnimationController.reverse();
        });
      }
    });
  }

  Widget _buildActionsButton(
    AppThemeColors colors,
    bool isDark,
    bool isTablet,
  ) {
    return Builder(
      builder: (context) => GestureDetector(
        onTap: () {
          setState(() {
            _showActions = !_showActions;
            if (_showActions) {
              _actionsAnimationController.forward();
              _showActionsMenu(context, colors, isDark);
            } else {
              _actionsAnimationController.reverse();
            }
          });
        },
        child: Container(
          padding: EdgeInsets.symmetric(
            vertical: isTablet ? 10 : 8,
            horizontal: isTablet ? 16 : 14,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _showActions
                  ? [Colors.green.shade400, Colors.green.shade600]
                  : [Colors.green.shade500, Colors.green.shade700],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "ACTIONS",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isTablet ? 13 : 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(width: 6),
              AnimatedRotation(
                turns: _showActions ? 0.5 : 0,
                duration: const Duration(milliseconds: 300),
                child: Icon(
                  Icons.keyboard_arrow_up_rounded,
                  color: Colors.white,
                  size: isTablet ? 20 : 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getActionIcon(String action) {
    switch (action) {
      case "Add Survey":
        return Icons.poll_outlined;
      case "Add Comment":
        return Icons.comment_outlined;
      case "Add Delivery":
        return Icons.local_shipping_outlined;
      case "View Tax":
        return Icons.receipt_long_outlined;
      case "View Profit":
        return Icons.trending_up_outlined;
      case "Finalise":
        return Icons.check_circle_outline;
      default:
        return Icons.more_horiz;
    }
  }

  Widget _buildTaxBreakdown(AppThemeColors colors, bool isDark) {
    return TaxBreakdownWidget(total: _total, colors: colors, isDark: isDark);
  }

  Widget _buildProfitBreakdown(AppThemeColors colors, bool isDark) {
    return ProfitBreakdownWidget(
      subtotal: _subtotal,
      discount: _discount,
      colors: colors,
      isDark: isDark,
    );
  }
}
