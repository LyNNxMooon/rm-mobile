import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../entities/response/customer_search_response.dart';
import '../../../../entities/vos/cart_item_vo.dart';
import '../../../../entities/vos/customer_vo.dart';
import '../../../../entities/vos/stock_vo.dart';
import '../../../../utils/tax_calculation_utils.dart';
import '../../domain/models/low_stock_warning.dart';
import '../../domain/use_cases/search_stock_for_sale.dart';
import '../../domain/use_cases/search_customer_for_sale.dart';
import '../../domain/use_cases/check_low_stock_warning.dart';
import '../../domain/use_cases/check_stock_availability.dart';
import '../../domain/use_cases/validate_out_of_stock_items.dart';
import '../../domain/use_cases/get_sale_sessions.dart';
import '../../domain/use_cases/save_sale_session.dart';
import '../../domain/use_cases/delete_sale_session.dart';
import '../../domain/use_cases/restore_sale_session.dart';
import '../../domain/use_cases/load_sales_settings.dart';
import '../../domain/use_cases/save_sales_setting.dart';
import '../../domain/use_cases/create_account_invoice.dart';
import '../../domain/use_cases/create_sales_order.dart';
import '../../domain/use_cases/create_quote.dart';
import '../../domain/use_cases/create_layby.dart';
import '../../domain/use_cases/get_cash_drawer_identifier.dart';
import '../../../customer_lookup/domain/use_cases/update_customer_details.dart';
import 'sales_events.dart';
import 'sales_states.dart';

class SalesBloc extends Bloc<SalesEvent, SalesState> {
  final SearchStockForSale searchStockForSale;
  final SearchCustomerForSale searchCustomerForSale;
  final CheckLowStockWarning checkLowStockWarning;
  final CheckStockAvailability checkStockAvailability;
  final ValidateOutOfStockItems validateOutOfStockItems;
  final GetSaleSessions getSaleSessions;
  final SaveSaleSession saveSaleSession;
  final DeleteSaleSession deleteSaleSession;
  final RestoreSaleSession restoreSaleSession;
  final LoadSalesSettings loadSalesSettings;
  final SaveSalesSetting saveSalesSetting;
  final CreateAccountInvoice createAccountInvoice;
  final CreateSalesOrder createSalesOrder;
  final CreateQuote createQuote;
  final CreateLayby createLayby;
  final GetCashDrawerIdentifier getCashDrawerIdentifier;
  final UpdateCustomerDetails updateCustomerDetails;
  final List<CartItemVO> _cartItems = [];
  CustomerVO? _selectedCustomer;

  SalesBloc({
    required this.searchStockForSale,
    required this.searchCustomerForSale,
    required this.checkLowStockWarning,
    required this.checkStockAvailability,
    required this.validateOutOfStockItems,
    required this.getSaleSessions,
    required this.saveSaleSession,
    required this.deleteSaleSession,
    required this.restoreSaleSession,
    required this.loadSalesSettings,
    required this.saveSalesSetting,
    required this.createAccountInvoice,
    required this.createSalesOrder,
    required this.createQuote,
    required this.createLayby,
    required this.getCashDrawerIdentifier,
    required this.updateCustomerDetails,
  }) : super(const SalesInitial()) {
    on<SearchStock>(_onSearchStock);
    on<SelectStock>(_onSelectStock);
    on<AddToCart>(_onAddToCart);
    on<AddCartItemDirect>(_onAddCartItemDirect);
    on<UpdateCartItemQty>(_onUpdateCartItemQty);
    on<UpdateCartItemPrice>(_onUpdateCartItemPrice);
    on<UpdateCartItemSerial>(_onUpdateCartItemSerial);
    on<UpdateCartItemDescription>(_onUpdateCartItemDescription);
    on<SaveCartItem>(_onSaveCartItem);
    on<EditCartItem>(_onEditCartItem);
    on<RemoveCartItem>(_onRemoveCartItem);
    on<ClearCart>(_onClearCart);
    on<ResetSearchState>(_onResetSearchState);
    on<RecalculatePricesForGrade>(_onRecalculatePricesForGrade);
    // Customer events
    on<SearchCustomer>(_onSearchCustomer);
    on<SelectCustomer>(_onSelectCustomer);
    on<ClearCustomer>(_onClearCustomer);
  }

  Future<String> fetchCashDrawerIdentifier({String fallback = 'A'}) {
    return getCashDrawerIdentifier(fallback: fallback);
  }

  Future<CustomerSearchResult> searchCustomer(String query) {
    return searchCustomerForSale(query);
  }

  Future<void> _onRecalculatePricesForGrade(
    RecalculatePricesForGrade event,
    Emitter<SalesState> emit,
  ) async {
    await _recalculateCartPricesForGrade(event.grade);
    emit(CartUpdated(
      cartItems: List.from(_cartItems),
      selectedCustomer: _selectedCustomer,
    ));
  }

  Future<void> _onSearchStock(
    SearchStock event,
    Emitter<SalesState> emit,
  ) async {
    if (event.query.trim().isEmpty) return;

    emit(StockSearching(cartItems: List.from(_cartItems), selectedCustomer: _selectedCustomer));

    try {
      final result = await searchStockForSale(event.query.trim());

      if (result.notFound) {
        emit(StockNotFound(
          message: "Stock not found!",
          cartItems: List.from(_cartItems),
          selectedCustomer: _selectedCustomer,
        ));
        return;
      }

      if (result.duplicates.isNotEmpty) {
        emit(StockDuplicatesFound(
          matches: result.duplicates,
          cartItems: List.from(_cartItems),
          selectedCustomer: _selectedCustomer,
        ));
        return;
      }

      if (result.stock != null) {
        // Calculate what the total qty would be if added
        final double qtyToAdd = 1.0;
        final double totalQty =
            _cartQtyForCode(result.stock!.barcode) + qtyToAdd;
        
        // Check if adding is permitted (stock availability)
        final availability = checkStockAvailability(
          stock: result.stock!,
          saleQty: totalQty,
          preventAddIfNoStock: event.preventAddIfNoStock,
        );
        
        if (!availability.canAdd) {
          emit(StockNotPermitted(
            message: availability.message ?? '',
            cartItems: List.from(_cartItems),
            selectedCustomer: _selectedCustomer,
          ));
          return;
        }
        
        // Check if this is a fractional item and skipEditMode was requested
        // If so, let the UI handle the fractional item settings
        if (event.skipEditMode && result.stock!.allowFractions) {
          emit(FractionalItemFound(
            stock: result.stock!,
            cartItems: List.from(_cartItems),
            selectedCustomer: _selectedCustomer,
          ));
          return;
        }
        
        // Auto-add to cart when single match found
        final added = await _addStockToCart(
          result.stock!,
          skipEditMode: event.skipEditMode,
          oneDisplayLinePerItem: event.oneDisplayLinePerItem,
        );
        if (added.negativeSellPrice) {
          emit(NegativeSellPriceFound(
            cartItems: List.from(_cartItems),
            selectedCustomer: _selectedCustomer,
          ));
          return;
        }
        
        // Check for low stock warning - only show on add if skipEditMode is true
        // (if in edit mode, warning will show when user hits save)
        LowStockWarning? warning;
        if (event.skipEditMode) {
          warning = checkLowStockWarning(
            stock: result.stock!,
            saleQty: added.totalQty,
            autoRemindEnabled: event.autoRemindLowStock,
          );
          if (!warning.hasWarning) warning = null;
        }
        
        emit(CartUpdated(
          cartItems: List.from(_cartItems),
          selectedCustomer: _selectedCustomer,
          lowStockWarning: warning,
          salesPrompt: added.salesPrompt,
        ));
        return;
      }

      emit(StockNotFound(
        message: "Stock not found!",
        cartItems: List.from(_cartItems),
        selectedCustomer: _selectedCustomer,
      ));
    } catch (error) {
      emit(StockSearchError(
        error: "Error searching stock: $error",
        cartItems: List.from(_cartItems),
        selectedCustomer: _selectedCustomer,
      ));
    }
  }

  Future<void> _onSelectStock(SelectStock event, Emitter<SalesState> emit) async {
    // Calculate what the total qty would be if added
    final double qtyToAdd = 1.0;
    final double totalQty = _cartQtyForCode(event.stock.barcode) + qtyToAdd;
    
    // Check if adding is permitted (stock availability)
    final availability = checkStockAvailability(
      stock: event.stock,
      saleQty: totalQty,
      preventAddIfNoStock: event.preventAddIfNoStock,
    );
    
    if (!availability.canAdd) {
      emit(StockNotPermitted(
        message: availability.message ?? '',
        cartItems: List.from(_cartItems),
        selectedCustomer: _selectedCustomer,
      ));
      return;
    }
    
    // Check if this is a fractional item and skipEditMode was requested
    // If so, let the UI handle the fractional item settings
    // (but not if already being handled - check via skipFractionalCheck flag)
    if (event.skipEditMode && event.stock.allowFractions && !event.skipFractionalCheck) {
      emit(FractionalItemFound(
        stock: event.stock,
        cartItems: List.from(_cartItems),
        selectedCustomer: _selectedCustomer,
      ));
      return;
    }
    
    final added = await _addStockToCart(
      event.stock,
      skipEditMode: event.skipEditMode,
      oneDisplayLinePerItem: event.oneDisplayLinePerItem,
    );
    if (added.negativeSellPrice) {
      emit(NegativeSellPriceFound(
        cartItems: List.from(_cartItems),
        selectedCustomer: _selectedCustomer,
      ));
      return;
    }
    
    // Check for low stock warning - only show on add if skipEditMode is true
    // (if in edit mode, warning will show when user hits save)
    LowStockWarning? warning;
    if (event.skipEditMode) {
      warning = checkLowStockWarning(
        stock: event.stock,
        saleQty: added.totalQty,
        autoRemindEnabled: event.autoRemindLowStock,
      );
      if (!warning.hasWarning) warning = null;
    }
    
    emit(CartUpdated(
      cartItems: List.from(_cartItems),
      selectedCustomer: _selectedCustomer,
      lowStockWarning: warning,
      salesPrompt: added.salesPrompt,
    ));
  }

  Future<void> _onAddToCart(AddToCart event, Emitter<SalesState> emit) async {
    // Calculate what the total qty would be if added
    final double totalQty = _cartQtyForCode(event.stock.barcode) + event.qty;
    
    // Check if adding is permitted (stock availability)
    final availability = checkStockAvailability(
      stock: event.stock,
      saleQty: totalQty,
      preventAddIfNoStock: event.preventAddIfNoStock,
    );
    
    if (!availability.canAdd) {
      emit(StockNotPermitted(
        message: availability.message ?? '',
        cartItems: List.from(_cartItems),
        selectedCustomer: _selectedCustomer,
      ));
      return;
    }
    
    final result = await _addStockToCart(
      event.stock,
      qty: event.qty,
      skipEditMode: event.skipEditMode,
      oneDisplayLinePerItem: event.oneDisplayLinePerItem,
    );
    if (result.negativeSellPrice) {
      emit(NegativeSellPriceFound(
        cartItems: List.from(_cartItems),
        selectedCustomer: _selectedCustomer,
      ));
      return;
    }
    
    // Check for low stock warning - only show on add if skipEditMode is true
    // (if in edit mode, warning will show when user hits save)
    LowStockWarning? warning;
    if (event.skipEditMode) {
      warning = checkLowStockWarning(
        stock: event.stock,
        saleQty: result.totalQty,
        autoRemindEnabled: event.autoRemindLowStock,
      );
      if (!warning.hasWarning) warning = null;
    }
    
    emit(CartUpdated(
      cartItems: List.from(_cartItems),
      selectedCustomer: _selectedCustomer,
      lowStockWarning: warning,
      salesPrompt: result.salesPrompt,
    ));
  }

  void _onAddCartItemDirect(AddCartItemDirect event, Emitter<SalesState> emit) {
    // Add the cart item directly without searching for stock
    _cartItems.insert(0, event.cartItem);
    emit(CartUpdated(
      cartItems: List.from(_cartItems),
      selectedCustomer: _selectedCustomer,
    ));
  }

  double _cartQtyForCode(String code) {
    double total = 0.0;
    for (final item in _cartItems) {
      if (item.code == code) {
        total += item.qty;
      }
    }
    return total;
  }

  bool _pricesMatch(CartItemVO item, double incPrice) {
    const double epsilon = 0.0001;
    return (item.sellPrice - incPrice).abs() <= epsilon;
  }

  int _findMatchingCartIndex(
    String code,
    double incPrice, {
    int excludeIndex = -1,
  }) {
    for (int i = 0; i < _cartItems.length; i++) {
      if (i == excludeIndex) {
        continue;
      }
      final item = _cartItems[i];
      if (item.code == code && _pricesMatch(item, incPrice)) {
        return i;
      }
    }
    return -1;
  }

  /// Adds stock to cart and returns the total quantity in cart for this item
  Future<_AddToCartResult> _addStockToCart(
    StockVO stock, {
    double qty = 1.0,
    bool skipEditMode = false,
    bool oneDisplayLinePerItem = true,
  }) async {
    // Add new item - determine prices
    double incPrice;
    double exPrice;
    double taxPercentage;
    int taxType;

    // Get effective sell price based on customer grade
    final int customerGrade = _selectedCustomer?.grade ?? 0;
    final effectiveResult = stock.getEffectiveSellPrice(customerGrade);
    final double effectiveSell = effectiveResult.price;

    // Get tax info for this stock (needed for taxType and percentage)
    final taxResult = await TaxCalculationUtils.calculateSellTax(
      sell: stock.sell,
      salesTax: stock.salesTax,
    );
    taxPercentage = taxResult.percentage;
    taxType = taxResult.taxType;

    if (effectiveResult.isPricingGradeApplied) {
      // Pricing grade prices are already inc-tax
      // Calculate ex-tax from inc using precise Rational arithmetic
      incPrice = effectiveSell;
      exPrice = taxPercentage > 0
          ? TaxCalculationUtils.calculateExclusivePrice(
              effectiveSell,
              taxPercentage,
            )
          : effectiveSell;
    } else if (stock.sellInc != null && stock.sellEx != null) {
      // Use pre-calculated values from server (for both normal & package items)
      incPrice = stock.sellInc!;
      exPrice = stock.sellEx!;
    } else {
      // Fallback: calculate using tax tables (legacy items without pre-calculated values)
      incPrice = taxResult.incPrice;
      exPrice = taxResult.exPrice;
    }

    // Get cost values - use pre-calculated from server when available
    double computedCostEx;
    double computedCostInc;

    if (stock.costEx != null && stock.costInc != null) {
      // Use pre-calculated values from server
      computedCostEx = stock.costEx!;
      computedCostInc = stock.costInc!;
    } else if (stock.costEx != null) {
      // Only costEx available - calculate costInc with precise arithmetic
      computedCostEx = stock.costEx!;
      final costTaxResult = await TaxCalculationUtils.calculateCostTax(
        cost: stock.cost,
        goodsTax: stock.goodsTax,
      );
      computedCostInc = costTaxResult.percentage > 0
          ? TaxCalculationUtils.calculateInclusivePrice(
              computedCostEx,
              costTaxResult.percentage,
            )
          : computedCostEx;
    } else if (stock.costInc != null) {
      // Only costInc available - calculate costEx with precise arithmetic
      computedCostInc = stock.costInc!;
      final costTaxResult = await TaxCalculationUtils.calculateCostTax(
        cost: stock.cost,
        goodsTax: stock.goodsTax,
      );
      computedCostEx = costTaxResult.percentage > 0
          ? TaxCalculationUtils.calculateExclusivePrice(
              computedCostInc,
              costTaxResult.percentage,
            )
          : computedCostInc;
    } else if (stock.cost > 0) {
      // Fallback: calculate using tax tables (legacy items)
      final costTaxResult = await TaxCalculationUtils.calculateCostTax(
        cost: stock.cost,
        goodsTax: stock.goodsTax,
      );
      computedCostEx = costTaxResult.exPrice;
      computedCostInc = costTaxResult.incPrice;
    } else {
      computedCostEx = 0.0;
      computedCostInc = 0.0;
    }

    final bool negativeSellPrice =
        effectiveSell < 0 || incPrice < 0 || exPrice < 0;

    int matchingIndex = -1;
    if (oneDisplayLinePerItem && skipEditMode) {
      matchingIndex = _findMatchingCartIndex(stock.barcode, incPrice);
    }

    String? salesPrompt;

    if (matchingIndex >= 0) {
      final updatedQty = _cartItems[matchingIndex].qty + qty;
      _cartItems[matchingIndex] = _cartItems[matchingIndex].copyWith(
        qty: updatedQty,
        isEditing: skipEditMode ? false : true,
      );
    } else {
      final newItem = CartItemVO(
        code: stock.barcode,
        description: stock.description,
        qty: qty,
        sellPrice: effectiveSell,
        costPrice: stock.cost,
        stock: stock,
        isEditing: negativeSellPrice ? true : !skipEditMode,
        isNewlyAdded: negativeSellPrice ? true : !skipEditMode,
        taxPercentage: taxPercentage,
        taxType: taxType,
        incPrice: incPrice,
        exPrice: exPrice,
        computedCostEx: computedCostEx,
        computedCostInc: computedCostInc,
      );

      _cartItems.insert(0, newItem);

      final prompt = stock.salesPrompt?.trim() ?? '';
      if (prompt.isNotEmpty) {
        salesPrompt = prompt;
      }
    }

    return _AddToCartResult(
      totalQty: _cartQtyForCode(stock.barcode),
      negativeSellPrice: negativeSellPrice,
      salesPrompt: salesPrompt,
    );
  }

  void _onUpdateCartItemQty(
    UpdateCartItemQty event,
    Emitter<SalesState> emit,
  ) {
    if (event.index < 0 || event.index >= _cartItems.length) return;

    _cartItems[event.index] = _cartItems[event.index].copyWith(qty: event.qty);
    emit(CartUpdated(cartItems: List.from(_cartItems), selectedCustomer: _selectedCustomer));
  }

  void _onUpdateCartItemPrice(
    UpdateCartItemPrice event,
    Emitter<SalesState> emit,
  ) {
    if (event.index < 0 || event.index >= _cartItems.length) return;
    if (event.price < 0) return;

    final item = _cartItems[event.index];
    final percentage = item.taxPercentage;
    
    double incPrice;
    double exPrice;
    
    if (event.isIncPrice) {
      // User edited the Inc price - calculate Ex with precise Rational arithmetic
      incPrice = event.price;
      exPrice = percentage > 0 
          ? TaxCalculationUtils.calculateExclusivePrice(event.price, percentage)
          : event.price;
    } else {
      // User edited the Ex price - calculate Inc with precise Rational arithmetic
      exPrice = event.price;
      incPrice = percentage > 0 
          ? TaxCalculationUtils.calculateInclusivePrice(event.price, percentage)
          : event.price;
    }

    _cartItems[event.index] = item.copyWith(
      sellPrice: incPrice, // sellPrice stores the base price as inc
      incPrice: incPrice,
      exPrice: exPrice,
      isPriceOverridden: true,
    );
    emit(CartUpdated(cartItems: List.from(_cartItems), selectedCustomer: _selectedCustomer));
  }

  void _onUpdateCartItemSerial(
    UpdateCartItemSerial event,
    Emitter<SalesState> emit,
  ) {
    if (event.index < 0 || event.index >= _cartItems.length) return;

    _cartItems[event.index] = _cartItems[event.index].copyWith(
      serialNumbers: event.serialNumbers,
    );
    emit(CartUpdated(cartItems: List.from(_cartItems), selectedCustomer: _selectedCustomer));
  }

  void _onUpdateCartItemDescription(
    UpdateCartItemDescription event,
    Emitter<SalesState> emit,
  ) {
    if (event.index < 0 || event.index >= _cartItems.length) return;

    _cartItems[event.index] = _cartItems[event.index].copyWith(
      description: event.description,
    );
    emit(CartUpdated(cartItems: List.from(_cartItems), selectedCustomer: _selectedCustomer));
  }

  void _onSaveCartItem(SaveCartItem event, Emitter<SalesState> emit) {
    if (event.index < 0 || event.index >= _cartItems.length) return;

    final cartItem = _cartItems[event.index];
    if (cartItem.sellPrice < 0 || cartItem.incPrice < 0 || cartItem.exPrice < 0) {
      emit(NegativeSellPriceFound(
        cartItems: List.from(_cartItems),
        selectedCustomer: _selectedCustomer,
      ));
      return;
    }

    _cartItems[event.index] = cartItem.copyWith(
      isEditing: false,
      isNewlyAdded: false,
    );

    int savedIndex = event.index;
    if (event.oneDisplayLinePerItem) {
      final updatedItem = _cartItems[event.index];
      final matchingIndex = _findMatchingCartIndex(
        updatedItem.code,
        updatedItem.sellPrice,
        excludeIndex: event.index,
      );

      if (matchingIndex >= 0 && matchingIndex != event.index) {
        final mergedQty = _cartItems[matchingIndex].qty + updatedItem.qty;
        _cartItems[matchingIndex] = _cartItems[matchingIndex].copyWith(
          qty: mergedQty,
          isEditing: false,
          isNewlyAdded: false,
        );
        _cartItems.removeAt(event.index);
        savedIndex = matchingIndex > event.index
            ? matchingIndex - 1
            : matchingIndex;
      }
    }

    // Check for low stock warning if the setting is enabled and stock data is available
    LowStockWarning? warning;
    final warningItem = _cartItems[savedIndex];
    if (event.autoRemindLowStock && warningItem.stock != null) {
      warning = checkLowStockWarning(
        stock: warningItem.stock!,
        saleQty: warningItem.qty,
        autoRemindEnabled: true,
      );
      if (!warning.hasWarning) warning = null;
    }

    emit(CartItemSaved(
      index: savedIndex,
      cartItems: List.from(_cartItems),
      selectedCustomer: _selectedCustomer,
      lowStockWarning: warning,
    ));
  }

  void _onEditCartItem(EditCartItem event, Emitter<SalesState> emit) {
    if (event.index < 0 || event.index >= _cartItems.length) return;

    // First, close any other items that are in edit mode
    for (int i = 0; i < _cartItems.length; i++) {
      if (_cartItems[i].isEditing) {
        _cartItems[i] = _cartItems[i].copyWith(isEditing: false);
      }
    }

    _cartItems[event.index] = _cartItems[event.index].copyWith(isEditing: true);
    emit(CartUpdated(cartItems: List.from(_cartItems), selectedCustomer: _selectedCustomer));
  }

  void _onRemoveCartItem(RemoveCartItem event, Emitter<SalesState> emit) {
    if (event.index < 0 || event.index >= _cartItems.length) return;

    _cartItems.removeAt(event.index);
    emit(CartUpdated(
      cartItems: List.from(_cartItems),
      selectedCustomer: _selectedCustomer,
    ));
  }

  void _onClearCart(ClearCart event, Emitter<SalesState> emit) {
    _cartItems.clear();
    emit(CartUpdated(
      cartItems: List.from(_cartItems),
      selectedCustomer: _selectedCustomer,
    ));
  }

  void _onResetSearchState(ResetSearchState event, Emitter<SalesState> emit) {
    emit(CartUpdated(cartItems: List.from(_cartItems), selectedCustomer: _selectedCustomer));
  }

  // ==================== CUSTOMER HANDLERS ====================

  Future<void> _onSearchCustomer(
    SearchCustomer event,
    Emitter<SalesState> emit,
  ) async {
    if (event.query.trim().isEmpty) return;

    emit(CustomerSearching(cartItems: List.from(_cartItems), selectedCustomer: _selectedCustomer));

    try {
      final result = await searchCustomerForSale(event.query.trim());

      if (result.notFound) {
        emit(CustomerNotFound(
          message: "Customer not found!",
          cartItems: List.from(_cartItems),
          selectedCustomer: _selectedCustomer,
        ));
        return;
      }

      if (result.duplicates.isNotEmpty) {
        emit(CustomerDuplicatesFound(
          matches: result.duplicates,
          cartItems: List.from(_cartItems),
          selectedCustomer: _selectedCustomer,
        ));
        return;
      }

      if (result.customer != null) {
        _selectedCustomer = result.customer;
        emit(CustomerSelected(
          cartItems: List.from(_cartItems),
          selectedCustomer: _selectedCustomer,
        ));
        return;
      }

      emit(CustomerNotFound(
        message: "Customer not found!",
        cartItems: List.from(_cartItems),
        selectedCustomer: _selectedCustomer,
      ));
    } catch (error) {
      emit(CustomerSearchError(
        error: "Error searching customer: $error",
        cartItems: List.from(_cartItems),
        selectedCustomer: _selectedCustomer,
      ));
    }
  }

  Future<void> _onSelectCustomer(SelectCustomer event, Emitter<SalesState> emit) async {
    _selectedCustomer = event.customer;
    
    // Recalculate cart prices based on new customer's grade
    await _recalculateCartPricesForGrade(event.customer.grade);
    
    emit(CustomerSelected(
      cartItems: List.from(_cartItems),
      selectedCustomer: _selectedCustomer,
    ));
  }

  Future<void> _onClearCustomer(ClearCustomer event, Emitter<SalesState> emit) async {
    _selectedCustomer = null;
    
    // Recalculate cart prices back to default grade (0)
    await _recalculateCartPricesForGrade(0);
    
    emit(CartUpdated(
      cartItems: List.from(_cartItems),
      selectedCustomer: null,
    ));
  }

  /// Recalculates all cart item prices based on the given customer grade
  Future<void> _recalculateCartPricesForGrade(int customerGrade) async {
    for (int i = 0; i < _cartItems.length; i++) {
      final item = _cartItems[i];
      final stock = item.stock;
      
      if (stock == null) continue; // Skip items without stock reference
      if (item.isPriceOverridden) continue; // Preserve manual or grade overrides
      
      // Get effective sell price based on customer grade
      final effectiveResult = stock.getEffectiveSellPrice(customerGrade);
      final double effectiveSell = effectiveResult.price;
      
      double incPrice;
      double exPrice;
      double taxPercentage;
      int taxType;
      
      if (effectiveResult.isPricingGradeApplied) {
        // Pricing grade prices are already inc-tax (applies to both package and normal items)
        // Get tax percentage from tax tables, then calculate ex-tax from inc
        final taxResult = await TaxCalculationUtils.calculateSellTax(
          sell: stock.sell,
          salesTax: stock.salesTax,
        );
        taxPercentage = taxResult.percentage;
        taxType = taxResult.taxType;
        
        // effectiveSell is already inc-tax
        incPrice = effectiveSell;
        final multiplier = 1 + (taxPercentage / 100);
        exPrice = taxPercentage > 0 ? effectiveSell / multiplier : effectiveSell;
      } else if (stock.isPackage && stock.sellEx != null && stock.sellInc != null) {
        // Package items with no pricing grade: keep original sellInc/sellEx
        incPrice = stock.sellInc!;
        exPrice = stock.sellEx!;
        taxPercentage = exPrice > 0 ? ((incPrice - exPrice) / exPrice) * 100 : 0.0;
        // Look up actual taxType from sales_tax (for GP calculation)
        final taxResult = await TaxCalculationUtils.calculateSellTax(
          sell: stock.sell,
          salesTax: stock.salesTax,
        );
        taxType = taxResult.taxType;
      } else {
        // Regular RRP - calculate using tax tables
        final taxResult = await TaxCalculationUtils.calculateSellTax(
          sell: effectiveSell,
          salesTax: stock.salesTax,
        );
        incPrice = taxResult.incPrice;
        exPrice = taxResult.exPrice;
        taxPercentage = taxResult.percentage;
        taxType = taxResult.taxType;
      }
      
      _cartItems[i] = item.copyWith(
        sellPrice: effectiveSell,
        incPrice: incPrice,
        exPrice: exPrice,
        taxPercentage: taxPercentage,
        taxType: taxType,
      );
    }
  }
}

class _AddToCartResult {
  final double totalQty;
  final bool negativeSellPrice;
  final String? salesPrompt;

  _AddToCartResult({
    required this.totalQty,
    required this.negativeSellPrice,
    this.salesPrompt,
  });
}
