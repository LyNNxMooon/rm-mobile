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
import '../../../../entities/vos/sale_session_vo.dart';
import '../../../../utils/global_var_utils.dart';
import '../../../../entities/vos/stock_vo.dart';
import '../../../../utils/navigation_extension.dart';
import '../../../../entities/vos/cart_item_vo.dart';
import '../../../../local_db/local_db_dao.dart';
import '../../../../local_db/sqlite/sqlite_constants.dart';
import '../BLoC/sales_bloc.dart';
import '../BLoC/sales_events.dart';
import '../BLoC/sales_states.dart';
import 'stock_selection_screen.dart';
import 'customer_selection_screen.dart';
import '../widgets/finalise_sale_dialog.dart';
import '../widgets/sale_session_picker_dialog.dart';
import '../widgets/sales_widgets.dart';
import '../models/delivery_info.dart';
import '../../../../utils/responsive_utils.dart';
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
  final bool _showTaxDetails = false;
  final bool _showProfitDetails = false;
  String? _selectedOption;
  double _discountValue = 0.00;

  // Sales Settings
  bool _scanIndividualUnits = false;
  bool _skipSellPrice = false;
  bool _promptForEmailAtSale = false;
  bool _roundSellPriceTo2Decimals = false;
  bool _skipCustomField = false;
  bool _skipCustomerField = false;
  bool _scanIndividualUnitsForFractional = false;
  bool _preventAddIfNoStock = false;
  bool _preventFinaliseIfOutOfStock = false;
  bool _acceptLeadingZeros = false;
  bool _autoRemindLowStock = false;
  bool _promptScanIndividualFractional = false;
  bool _displayCustomerMessagesAsPrompt = false;

  // Payment amounts for each payment type
  final Map<String, double> _paymentAmounts = {};

  // Survey and Comment values
  String _surveyValue = '';
  String _commentValue = '';
  final TextEditingController _surveyController = TextEditingController();

  // Session tracking
  int? _currentSessionId;
  bool _sessionsChecked = false;

  late AnimationController _actionsAnimationController;
  late Animation<double> _actionsAnimation;

  final List<String> _optionItems = [
    "Add Survey",
    "Add Comment",
    "Add Discount",
    "Add Delivery",
    "View Tax",
    "View Profit",
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
    _loadSalesSettings();
    
    // Check for saved sessions after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkSavedSessions();
    });
  }

  Future<void> _checkSavedSessions() async {
    if (_sessionsChecked) return;
    _sessionsChecked = true;
    
    final shopfront = AppGlobals.instance.shopfront ?? '';
    if (shopfront.isEmpty) return;
    
    final sessionsData = await LocalDbDAO.instance.getSaleSessions(
      shopfront: shopfront,
      sessionType: widget.title,
    );
    
    if (sessionsData.isEmpty || !mounted) return;
    
    final sessions = sessionsData.map((e) => SaleSessionVO.fromMap(e)).toList();
    
    final result = await SaleSessionPickerDialog.show(
      context: context,
      sessions: sessions,
      sessionType: widget.title,
    );
    
    if (result == null || result.result == SessionPickerResult.cancelled) {
      return;
    }
    
    if (result.result == SessionPickerResult.continueSession && result.session != null) {
      await _restoreSession(result.session!);
    } else if (result.result == SessionPickerResult.newSale) {
      // Starting new sale - optionally clear old sessions
      // For now, we keep them so user can continue later
    }
  }

  Future<void> _restoreSession(SaleSessionVO session) async {
    _currentSessionId = session.id;
    
    // Restore cart items
    _salesBloc.add(ClearCart());
    for (final itemData in session.cartItems) {
      // Try to find stock from database for full data
      final stockSearch = await LocalDbDAO.instance.getStockBySearch(
        itemData.code,
        AppGlobals.instance.shopfront ?? '',
      );
      
      StockVO? stock;
      if (stockSearch.stock != null) {
        stock = stockSearch.stock;
      } else if (stockSearch.duplicates.isNotEmpty) {
        stock = stockSearch.duplicates.first;
      }
      
      final cartItem = CartItemVO(
        code: itemData.code,
        description: itemData.description,
        qty: itemData.qty,
        sellPrice: itemData.sellPrice,
        costPrice: itemData.costPrice,
        stock: stock,
        serialNumber: itemData.serialNumber,
        isEditing: false,
      );
      _salesBloc.add(AddCartItemDirect(cartItem: cartItem));
    }
    
    // Restore customer (if we have customer ID, try to look them up)
    if (session.customerId != null) {
      final customerSearch = await LocalDbDAO.instance.getCustomerBySearch(
        session.customerBarcode ?? '',
        AppGlobals.instance.shopfront ?? '',
      );
      if (customerSearch.customer != null) {
        _selectedCustomer = customerSearch.customer;
      }
    }
    
    // Restore other values
    setState(() {
      _discountValue = session.discount;
      _discountController.text = session.discount.toStringAsFixed(2);
      _paymentAmounts.clear();
      _paymentAmounts.addAll(session.paymentAmounts);
      _surveyValue = session.surveyValue ?? '';
      _surveyController.text = _surveyValue;
      _commentValue = session.commentValue ?? '';
    });
  }

  Future<void> _saveCurrentSession() async {
    // Only save if there are items in the cart
    if (_cartItems.isEmpty) {
      // If session exists but cart is now empty, delete it
      if (_currentSessionId != null) {
        await LocalDbDAO.instance.deleteSaleSession(_currentSessionId!);
        _currentSessionId = null;
      }
      return;
    }
    
    final shopfront = AppGlobals.instance.shopfront ?? '';
    if (shopfront.isEmpty) return;
    
    final now = DateTime.now();
    final cartItemsData = _cartItems.map((e) => CartItemData.fromCartItem(e)).toList();
    
    final sessionMap = {
      'session_type': widget.title,
      'shopfront': shopfront,
      'created_at': _currentSessionId != null ? now.toIso8601String() : now.toIso8601String(),
      'updated_at': now.toIso8601String(),
      'cart_items_json': _cartItems.isNotEmpty 
          ? cartItemsData.map((e) => e.toJson()).toList().toString().replaceAll('\'', '"')
          : null,
      'customer_id': _selectedCustomer?.customerId,
      'customer_barcode': _selectedCustomer?.barcode,
      'customer_name': _selectedCustomer != null 
          ? _buildCustomerDisplayName(_selectedCustomer!)
          : null,
      'subtotal': _subtotal,
      'discount': _discountValue,
      'payment_amounts_json': _paymentAmounts.isNotEmpty 
          ? _paymentAmounts.entries.map((e) => '"${e.key}":${e.value}').join(',')
          : null,
      'survey_value': _surveyValue.isNotEmpty ? _surveyValue : null,
      'comment_value': _commentValue.isNotEmpty ? _commentValue : null,
    };
    
    // Properly encode cart items
    if (_cartItems.isNotEmpty) {
      sessionMap['cart_items_json'] = '[${cartItemsData.map((e) => 
        '{"code":"${e.code}","description":"${e.description.replaceAll('"', '\\"')}","qty":${e.qty},"sell_price":${e.sellPrice},"cost_price":${e.costPrice ?? 0},"serial_number":${e.serialNumber != null ? '"${e.serialNumber}"' : 'null'},"stock_id":${e.stockId ?? 'null'}}'
      ).join(',')}]';
    }
    
    // Properly encode payment amounts
    if (_paymentAmounts.isNotEmpty) {
      sessionMap['payment_amounts_json'] = '{${_paymentAmounts.entries.map((e) => '"${e.key}":${e.value}').join(',')}}';
    }
    
    if (_currentSessionId != null) {
      sessionMap['id'] = _currentSessionId;
      await LocalDbDAO.instance.updateSaleSession(sessionMap);
    } else {
      _currentSessionId = await LocalDbDAO.instance.saveSaleSession(sessionMap);
    }
  }

  Future<void> _deleteCurrentSession() async {
    if (_currentSessionId != null) {
      await LocalDbDAO.instance.deleteSaleSession(_currentSessionId!);
      _currentSessionId = null;
    }
  }

  Future<void> _loadSalesSettings() async {
    final scanIndividualUnits = await LocalDbDAO.instance.getAppConfig(kSalesScanIndividualUnitsKey);
    final skipSellPrice = await LocalDbDAO.instance.getAppConfig(kSalesSkipSellPriceKey);
    final promptForEmail = await LocalDbDAO.instance.getAppConfig(kSalesPromptForEmailKey);
    if (mounted) {
      setState(() {
        _scanIndividualUnits = scanIndividualUnits == 'true';
        _skipSellPrice = skipSellPrice == 'true';
        _promptForEmailAtSale = promptForEmail == 'true';
      });
    }
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
    _salesBloc.add(SearchStock(
      query: barcode,
      skipEditMode: _scanIndividualUnits && _skipSellPrice,
    ));
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
    final bool isTablet = context.isTablet;

    return BlocProvider.value(
      value: _salesBloc,
      child: BlocListener<SalesBloc, SalesState>(
        listener: (context, state) async {
          if (state is StockDuplicatesFound) {
            // Navigate to stock selection screen
            final selected = await Navigator.push<StockVO>(
              context,
              MaterialPageRoute(
                builder: (_) => StockSelectionScreen(matches: state.matches),
              ),
            );

            if (selected != null && mounted) {
              _salesBloc.add(SelectStock(
                stock: selected,
                skipEditMode: _scanIndividualUnits && _skipSellPrice,
              ));
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
            // Navigate to customer selection screen
            final selected = await Navigator.push<CustomerVO>(
              context,
              MaterialPageRoute(
                builder: (_) => CustomerSelectionScreen(matches: state.matches),
              ),
            );

            if (selected != null && mounted) {
              // For Account Sales, validate customer is an account customer
              if (widget.title == "Account Sales" && !selected.account) {
                AlertInfo.show(
                  context: context,
                  text: "This customer is not an account customer",
                  typeInfo: TypeInfo.error,
                  backgroundColor: isDark ? colors.surface : kSecondaryColor,
                  iconColor: kErrorColor,
                  textColor: kErrorColor,
                  position: MessagePosition.top,
                  padding: 70,
                );
                _salesBloc.add(ResetSearchState());
              } else {
                _salesBloc.add(SelectCustomer(customer: selected));
                setState(() => _selectedCustomer = selected);
              }
            } else {
              _salesBloc.add(ResetSearchState());
            }
          } else if (state is CustomerSelected) {
            // For Account Sales, validate customer is an account customer
            if (widget.title == "Account Sales" && !(state.selectedCustomer?.account ?? false)) {
              AlertInfo.show(
                context: context,
                text: "This customer is not an account customer",
                typeInfo: TypeInfo.error,
                backgroundColor: isDark ? colors.surface : kSecondaryColor,
                iconColor: kErrorColor,
                textColor: kErrorColor,
                position: MessagePosition.top,
                padding: 70,
              );
            } else {
              setState(() => _selectedCustomer = state.selectedCustomer);
            }
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
            return PopScope(
              canPop: true,
              onPopInvokedWithResult: (didPop, result) async {
                if (didPop) {
                  // Save session when leaving the screen
                  await _saveCurrentSession();
                }
              },
              child: Scaffold(
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
                      autoFocusCustomer: widget.title != "Sales",
                      onCustomerSearch: (query) {
                        _salesBloc.add(SearchCustomer(query: query));
                      },
                      onCustomerClear: () {
                        _salesBloc.add(ClearCustomer());
                        setState(() => _selectedCustomer = null);
                      },
                    ),

                    // Scanner Area (hidden when keyboard is visible to prevent overflow)
                    if (_showScanner && MediaQuery.of(context).viewInsets.bottom == 0)
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
                        _salesBloc.add(SearchStock(
                          query: query,
                          skipEditMode: _scanIndividualUnits && _skipSellPrice,
                        ));
                      },
                    ),

                    // Bottom Section: Summary, Payment & Commit
                    _buildBottomSummary(colors, isDark, isTablet),
                  ],
                ),
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
            } else if (value == 'settings') {
              _showSalesSettingsDialog(context);
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
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'settings',
              child: Row(
                children: [
                  Icon(Icons.settings, size: 18, color: Colors.grey),
                  SizedBox(width: 8),
                  Text('Settings'),
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
        onDescriptionChanged: (description) {
          _salesBloc.add(
            UpdateCartItemDescription(index: index, description: description),
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
              // Totals Row
              IntrinsicHeight(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Actions Button and Finalise Button (left column)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Actions Button - offset upward
                        Transform.translate(
                          offset: Offset(0, isTablet ? -8 : -6),
                          child: _buildActionsButton(colors, isDark, isTablet),
                        ),
                        const SizedBox(height: 12),
                        // Finalise Button
                        _buildFinaliseButton(colors, isDark, isTablet),
                      ],
                    ),

                    const SizedBox(width: 5),

                    // Balance display
                    Expanded(
                      child: Transform.translate(
                        offset: Offset(isTablet ? -32 : 0, 0),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              // Balance label
                              Text(
                                "Balance",
                                style: TextStyle(
                                  fontSize: isTablet ? 14 : 12.5,
                                  color: colors.onSurfaceMuted,
                                ),
                              ),
                              SizedBox(height: isTablet ? 6 : 4),
                              // Balance amount in border
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isTablet ? 12 : 8,
                                  vertical: isTablet ? 2 : 7,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: (_total - _totalPaid) <= 0
                                        ? const Color(0xFF30B24C)
                                        : Colors.redAccent,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  "\$${(_totalPaid >= _total ? 0.0 : _total - _totalPaid).toStringAsFixed(2)}",
                                  style: TextStyle(
                                    fontSize: isTablet ? 22 : 18,
                                    letterSpacing: -0.5,
                                    color: (_total - _totalPaid) <= 0
                                        ? const Color(0xFF30B24C)
                                        : Colors.redAccent,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 5),

                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: isTablet ? 200 : 110,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            "Subtotal: \$${_subtotal.toStringAsFixed(2)}",
                            style: TextStyle(
                              color: colors.onSurfaceMuted,
                              fontSize: isTablet ? 14 : 12.5,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: isTablet ? 6 : 8),
                          Text(
                            "Discount: \$${_discount.toStringAsFixed(2)}",
                            style: TextStyle(
                              color: _discount > 0 ? kPrimaryColor : colors.onSurfaceMuted,
                              fontSize: isTablet ? 14 : 12.5,
                              fontWeight: _discount > 0 ? FontWeight.w600 : FontWeight.normal,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: isTablet ? 6 : 8),
                          Text(
                            "Rounding: \$${_rounding.toStringAsFixed(2)}",
                            style: TextStyle(
                              color: colors.onSurfaceMuted,
                              fontSize: isTablet ? 14 : 12.5,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: isTablet ? 14 : 22),
                          Transform.translate(
                            offset: Offset(0, isTablet ? 0 : -8),
                            child: Text(
                              "\$${_total.toStringAsFixed(2)}",
                              style: TextStyle(
                                fontSize: isTablet ? 22 : 18,
                                fontWeight: FontWeight.w900,
                                color: isDark ? Colors.white : Colors.black87,
                                letterSpacing: -0.5,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
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

  Future<void> _showFinaliseDialog() async {
    final isSales = widget.title == "Sales";
    
    final result = await FinaliseSaleDialog.show(
      context: context,
      customer: _selectedCustomer,
      total: _total,
      initialPaymentAmounts: Map.from(_paymentAmounts),
      promptForEmail: _promptForEmailAtSale,
      showPayments: isSales,
      title: widget.title,
    );

    if (result == null) {
      return;
    }

    // Always update payment amounts from dialog (even on cancel)
    if (result.paymentData != null) {
      setState(() {
        _paymentAmounts.clear();
        _paymentAmounts.addAll(result.paymentData!.paymentAmounts);
      });
    }

    if (result.result == FinaliseSaleResult.cancelled) {
      return;
    }

    // Handle the result
    if (result.result == FinaliseSaleResult.email) {
      final emailData = result.emailData;
      debugPrint('Sending receipt to: ${emailData?.email}');
    }

    // Clear everything
    _clearSale();
  }

  void _clearSale() {
    // Delete the current session since sale was committed
    _deleteCurrentSession();
    
    setState(() {
      _salesBloc.add(ClearCart());
      _selectedCustomer = null;
      _deliveryInfo = null;
      _paymentAmounts.clear();
      _discountValue = 0.00;
      _discountController.text = "0.00";
      _searchController.clear();
      _surveyValue = '';
      _surveyController.clear();
      _commentValue = '';
    });
  }

  Widget _buildSurveyMenuItem(
    BuildContext context,
    AppThemeColors colors,
    bool isDark,
    bool expanded,
    Function(bool) onExpandChanged,
  ) {
    final isTablet = context.isTablet;

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

  Widget _buildDiscountMenuItem(
    BuildContext context,
    AppThemeColors colors,
    bool isDark,
    bool expanded,
    Function(bool) onExpandChanged,
  ) {
    final isTablet = context.isTablet;
    final discountTextController = TextEditingController(
      text: _discountValue > 0 ? _discountValue.toStringAsFixed(2) : '',
    );

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
                        Icons.discount_outlined,
                        size: isTablet ? 22 : 18,
                        color: kPrimaryColor,
                      ),
                      SizedBox(width: isTablet ? 16 : 12),
                      Text(
                        "Add Discount",
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
                                  controller: discountTextController,
                                  autofocus: true,
                                  keyboardType: const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: isDark
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: "0.00",
                                    prefixText: "\$ ",
                                    prefixStyle: TextStyle(
                                      color: isDark
                                          ? Colors.white70
                                          : Colors.black54,
                                      fontSize: 16,
                                    ),
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
                                      _discountValue = double.tryParse(value.trim()) ?? 0.00;
                                      _discountController.text = _discountValue.toStringAsFixed(2);
                                    });
                                    onExpandChanged(false);
                                  },
                                ),
                              )
                            : TextField(
                                controller: discountTextController,
                                autofocus: true,
                                keyboardType: const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                                decoration: InputDecoration(
                                  hintText: "0.00",
                                  prefixText: "\$ ",
                                  prefixStyle: TextStyle(
                                    color: isDark
                                        ? Colors.white70
                                        : Colors.black54,
                                    fontSize: 12,
                                  ),
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
                                    _discountValue = double.tryParse(value.trim()) ?? 0.00;
                                    _discountController.text = _discountValue.toStringAsFixed(2);
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
                          _discountValue = double.tryParse(discountTextController.text.trim()) ?? 0.00;
                          _discountController.text = _discountValue.toStringAsFixed(2);
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
                    if (_discountValue > 0) ...[
                      SizedBox(width: isTablet ? 8 : 4),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _discountValue = 0.00;
                            _discountController.text = "0.00";
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
                    Icons.discount_outlined,
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
                          "Add Discount",
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

  void _showSalesSettingsDialog(BuildContext context) {
    final colors = context.appColors;
    final bool isDark = colors.isDark;
    final bool isTablet = context.isTablet;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: isDark ? colors.surfaceAlt : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              insetPadding: EdgeInsets.symmetric(
                horizontal: isTablet ? 60 : 20,
                vertical: isTablet ? 40 : 24,
              ),
              child: Container(
                width: isTablet ? 600 : double.infinity,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.85,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: kPrimaryColor,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.settings, color: Colors.white),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Sales Settings',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () => Navigator.pop(dialogContext),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),
                    // Content
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _buildSettingsCheckbox(
                              'Scan Individual Units',
                              _scanIndividualUnits,
                              (v) {
                                setDialogState(() => _scanIndividualUnits = v!);
                                setState(() {});
                                LocalDbDAO.instance.saveAppConfig(kSalesScanIndividualUnitsKey, v.toString());
                              },
                              isDark,
                              colors,
                            ),
                            _buildSettingsCheckbox(
                              'Skip Sell Price',
                              _skipSellPrice,
                              (v) {
                                setDialogState(() => _skipSellPrice = v!);
                                setState(() {});
                                LocalDbDAO.instance.saveAppConfig(kSalesSkipSellPriceKey, v.toString());
                              },
                              isDark,
                              colors,
                            ),
                            _buildSettingsCheckbox(
                              'Prompt for Email at Time of Sale',
                              _promptForEmailAtSale,
                              (v) {
                                setDialogState(() => _promptForEmailAtSale = v!);
                                setState(() {});
                                LocalDbDAO.instance.saveAppConfig(kSalesPromptForEmailKey, v.toString());
                              },
                              isDark,
                              colors,
                            ),
                            _buildSettingsCheckbox(
                              'Round Sell Price to 2 Decimals',
                              _roundSellPriceTo2Decimals,
                              (v) {
                                setDialogState(() => _roundSellPriceTo2Decimals = v!);
                                setState(() {});
                              },
                              isDark,
                              colors,
                            ),
                            _buildSettingsCheckbox(
                              'Skip Custom Field',
                              _skipCustomField,
                              (v) {
                                setDialogState(() => _skipCustomField = v!);
                                setState(() {});
                              },
                              isDark,
                              colors,
                            ),
                            _buildSettingsCheckbox(
                              'Skip Customer Field',
                              _skipCustomerField,
                              (v) {
                                setDialogState(() => _skipCustomerField = v!);
                                setState(() {});
                              },
                              isDark,
                              colors,
                            ),
                            _buildSettingsCheckbox(
                              'Scan Individual Units for Fractional Quantities',
                              _scanIndividualUnitsForFractional,
                              (v) {
                                setDialogState(() => _scanIndividualUnitsForFractional = v!);
                                setState(() {});
                              },
                              isDark,
                              colors,
                            ),
                            _buildSettingsCheckbox(
                              'Prevent adding item to any sale transaction if there is no stock on hand',
                              _preventAddIfNoStock,
                              (v) {
                                setDialogState(() => _preventAddIfNoStock = v!);
                                setState(() {});
                              },
                              isDark,
                              colors,
                            ),
                            _buildSettingsCheckbox(
                              'Prevent finalising SA and IV when any item is out of stock - SO, LB, & CSO Allowed',
                              _preventFinaliseIfOutOfStock,
                              (v) {
                                setDialogState(() => _preventFinaliseIfOutOfStock = v!);
                                setState(() {});
                              },
                              isDark,
                              colors,
                            ),
                            _buildSettingsCheckbox(
                              'Accept Leading Zeros on Barcodes',
                              _acceptLeadingZeros,
                              (v) {
                                setDialogState(() => _acceptLeadingZeros = v!);
                                setState(() {});
                              },
                              isDark,
                              colors,
                            ),
                            _buildSettingsCheckbox(
                              'Auto Remind - Low Stock',
                              _autoRemindLowStock,
                              (v) {
                                setDialogState(() => _autoRemindLowStock = v!);
                                setState(() {});
                              },
                              isDark,
                              colors,
                            ),
                            _buildSettingsCheckbox(
                              'Prompt for Scan Individual Units for Fractional Quantities',
                              _promptScanIndividualFractional,
                              (v) {
                                setDialogState(() => _promptScanIndividualFractional = v!);
                                setState(() {});
                              },
                              isDark,
                              colors,
                            ),
                            _buildSettingsCheckbox(
                              'Display customer messages as a Prompt during sale',
                              _displayCustomerMessagesAsPrompt,
                              (v) {
                                setDialogState(() => _displayCustomerMessagesAsPrompt = v!);
                                setState(() {});
                              },
                              isDark,
                              colors,
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Footer
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: isDark ? Colors.white12 : Colors.grey.shade200,
                          ),
                        ),
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Done',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
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
      },
    );
  }

  Widget _buildSettingsCheckbox(
    String label,
    bool value,
    ValueChanged<bool?> onChanged,
    bool isDark,
    AppThemeColors colors,
  ) {
    return CheckboxListTile(
      value: value,
      onChanged: onChanged,
      title: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
      activeColor: kPrimaryColor,
      checkColor: Colors.white,
      contentPadding: EdgeInsets.zero,
      dense: true,
      controlAffinity: ListTileControlAffinity.leading,
    );
  }

  void _showTaxDialog(
    BuildContext context,
    AppThemeColors colors,
    bool isDark,
  ) {
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
                      "Tax Breakdown",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(dialogContext).pop(),
                      child: Icon(
                        Icons.close,
                        size: 20,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildTaxBreakdown(colors, isDark),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showProfitDialog(
    BuildContext context,
    AppThemeColors colors,
    bool isDark,
  ) {
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
                      "Profit Breakdown",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(dialogContext).pop(),
                      child: Icon(
                        Icons.close,
                        size: 20,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildProfitBreakdown(colors, isDark),
                const SizedBox(height: 12),
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
    bool discountExpanded = false;
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
            final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
            return Stack(
              children: [
                Positioned(
                  left: 12,
                  bottom:
                      MediaQuery.of(context).size.height -
                      buttonPosition.dy +
                      8 +
                      keyboardHeight,
                  child: Material(
                    color: Colors.transparent,
                    child: SizedBox(
                      width: context.isTablet
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
                                                : item == "Add Discount"
                                                ? _buildDiscountMenuItem(
                                                    context,
                                                    colors,
                                                    isDark,
                                                    discountExpanded,
                                                    (expanded) {
                                                      setDialogState(() {
                                                        discountExpanded =
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
                                                          _showActions = false;
                                                          _actionsAnimationController
                                                              .reverse();
                                                        });
                                                        _showTaxDialog(
                                                          context,
                                                          colors,
                                                          isDark,
                                                        );
                                                      } else if (item ==
                                                          "View Profit") {
                                                        Navigator.of(
                                                          context,
                                                        ).pop();
                                                        setState(() {
                                                          _showActions = false;
                                                          _actionsAnimationController
                                                              .reverse();
                                                        });
                                                        _showProfitDialog(
                                                          context,
                                                          colors,
                                                          isDark,
                                                        );
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
    final size = isTablet ? 70.0 : 50.0;
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
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: isDark ? colors.surfaceAlt : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: isDark ? Colors.white30 : Colors.grey.shade400,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withOpacity(0.5)
                    : Colors.black.withOpacity(0.15),
                blurRadius: 12,
                spreadRadius: 1,
                offset: const Offset(0, 4),
              ),
              if (!isDark)
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  blurRadius: 6,
                  spreadRadius: 0,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Icon(
            Icons.menu,
            color: kPrimaryColor,
            size: isTablet ? 34 : 24,
          ),
        ),
      ),
    );
  }

  Widget _buildFinaliseButton(
    AppThemeColors colors,
    bool isDark,
    bool isTablet,
  ) {
    final isSales = widget.title == "Sales";
    final requiresCustomer = !isSales && _selectedCustomer == null;
    final isDisabled = _cartItems.isEmpty || requiresCustomer;
    
    return GestureDetector(
      onTap: isDisabled ? null : () => _showFinaliseDialog(),
      child: Opacity(
        opacity: isDisabled ? 0.4 : 1.0,
        child: Container(
          padding: EdgeInsets.symmetric(
            vertical: isTablet ? 10 : 14,
            horizontal: isTablet ? 52 : 10,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDisabled 
                  ? [Colors.grey.shade400, Colors.grey.shade500]
                  : [Colors.green.shade500, Colors.green.shade700],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: isDisabled ? [] : [
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
              Icon(
                Icons.check_circle_outline,
                color: Colors.white,
                size: isTablet ? 22 : 16,
              ),
              const SizedBox(width: 8),
              Text(
                "FINALISE",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isTablet ? 15 : 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
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
      case "Add Discount":
        return Icons.discount_outlined;
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
