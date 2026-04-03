import 'package:flutter_bloc/flutter_bloc.dart';
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
    // Customer events
    on<SearchCustomer>(_onSearchCustomer);
    on<SelectCustomer>(_onSelectCustomer);
    on<ClearCustomer>(_onClearCustomer);
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
        final existingIndex = _cartItems.indexWhere(
          (item) => item.code == result.stock!.barcode,
        );
        final double qtyToAdd = 1.0;
        final double totalQty = existingIndex >= 0 
            ? _cartItems[existingIndex].qty + qtyToAdd 
            : qtyToAdd;
        
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
        final addedQty = await _addStockToCart(result.stock!, skipEditMode: event.skipEditMode);
        
        // Check for low stock warning - only show on add if skipEditMode is true
        // (if in edit mode, warning will show when user hits save)
        LowStockWarning? warning;
        if (event.skipEditMode) {
          warning = checkLowStockWarning(
            stock: result.stock!,
            saleQty: addedQty,
            autoRemindEnabled: event.autoRemindLowStock,
          );
          if (!warning.hasWarning) warning = null;
        }
        
        emit(CartUpdated(
          cartItems: List.from(_cartItems),
          selectedCustomer: _selectedCustomer,
          lowStockWarning: warning,
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
    final existingIndex = _cartItems.indexWhere(
      (item) => item.code == event.stock.barcode,
    );
    final double qtyToAdd = 1.0;
    final double totalQty = existingIndex >= 0 
        ? _cartItems[existingIndex].qty + qtyToAdd 
        : qtyToAdd;
    
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
    
    final addedQty = await _addStockToCart(event.stock, skipEditMode: event.skipEditMode);
    
    // Check for low stock warning - only show on add if skipEditMode is true
    // (if in edit mode, warning will show when user hits save)
    LowStockWarning? warning;
    if (event.skipEditMode) {
      warning = checkLowStockWarning(
        stock: event.stock,
        saleQty: addedQty,
        autoRemindEnabled: event.autoRemindLowStock,
      );
      if (!warning.hasWarning) warning = null;
    }
    
    emit(CartUpdated(
      cartItems: List.from(_cartItems),
      selectedCustomer: _selectedCustomer,
      lowStockWarning: warning,
    ));
  }

  Future<void> _onAddToCart(AddToCart event, Emitter<SalesState> emit) async {
    // Calculate what the total qty would be if added
    final existingIndex = _cartItems.indexWhere(
      (item) => item.code == event.stock.barcode,
    );
    final double totalQty = existingIndex >= 0 
        ? _cartItems[existingIndex].qty + event.qty 
        : event.qty;
    
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
    
    final addedQty = await _addStockToCart(event.stock, qty: event.qty, skipEditMode: event.skipEditMode);
    
    // Check for low stock warning - only show on add if skipEditMode is true
    // (if in edit mode, warning will show when user hits save)
    LowStockWarning? warning;
    if (event.skipEditMode) {
      warning = checkLowStockWarning(
        stock: event.stock,
        saleQty: addedQty,
        autoRemindEnabled: event.autoRemindLowStock,
      );
      if (!warning.hasWarning) warning = null;
    }
    
    emit(CartUpdated(
      cartItems: List.from(_cartItems),
      selectedCustomer: _selectedCustomer,
      lowStockWarning: warning,
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

  /// Adds stock to cart and returns the total quantity in cart for this item
  Future<double> _addStockToCart(StockVO stock, {double qty = 1.0, bool skipEditMode = false}) async {
    // Check if item already exists in cart (by barcode)
    final existingIndex = _cartItems.indexWhere(
      (item) => item.code == stock.barcode,
    );

    double totalQty = qty;
    
    if (existingIndex >= 0) {
      // Update quantity of existing item
      totalQty = _cartItems[existingIndex].qty + qty;
      _cartItems[existingIndex] = _cartItems[existingIndex].copyWith(
        qty: totalQty,
        isEditing: skipEditMode ? false : true, // Skip edit mode if auto-adding
      );
    } else {
      // Add new item - calculate tax first
      double incPrice;
      double exPrice;
      double taxPercentage;
      int taxType;
      
      // Get effective sell price based on customer grade
      final int customerGrade = _selectedCustomer?.grade ?? 0;
      final effectiveResult = stock.getEffectiveSellPrice(customerGrade);
      final double effectiveSell = effectiveResult.price;
      
      // For package items, use sell_ex/sell_inc directly
      if (stock.isPackage && stock.sellEx != null && stock.sellInc != null) {
        incPrice = stock.sellInc!;
        exPrice = stock.sellEx!;
        // Calculate percentage from prices
        taxPercentage = exPrice > 0 ? ((incPrice - exPrice) / exPrice) * 100 : 0.0;
        taxType = 2; // Inc-tax base
      } else if (effectiveResult.isPricingGradeApplied) {
        // Pricing grade prices are already inc-tax
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
      } else {
        // Regular items - calculate using tax tables with base sell price
        final taxResult = await TaxCalculationUtils.calculateSellTax(
          sell: effectiveSell,
          salesTax: stock.salesTax,
        );
        incPrice = taxResult.incPrice;
        exPrice = taxResult.exPrice;
        taxPercentage = taxResult.percentage;
        taxType = taxResult.taxType;
      }
      
      final newItem = CartItemVO(
        code: stock.barcode,
        description: stock.description,
        qty: qty,
        sellPrice: effectiveSell,
        costPrice: stock.cost,
        stock: stock,
        isEditing: !skipEditMode, // New items start in edit mode unless skipEditMode
        isNewlyAdded: !skipEditMode, // Mark as newly added for auto-save check
        taxPercentage: taxPercentage,
        taxType: taxType,
        incPrice: incPrice,
        exPrice: exPrice,
      );
      
      _cartItems.insert(0, newItem);
    }
    
    return totalQty;
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

    final item = _cartItems[event.index];
    final percentage = item.taxPercentage;
    final multiplier = 1 + (percentage / 100);
    
    double incPrice;
    double exPrice;
    
    if (event.isIncPrice) {
      // User edited the Inc price
      incPrice = event.price;
      exPrice = percentage > 0 ? event.price / multiplier : event.price;
    } else {
      // User edited the Ex price
      exPrice = event.price;
      incPrice = percentage > 0 ? event.price * multiplier : event.price;
    }

    _cartItems[event.index] = item.copyWith(
      sellPrice: incPrice, // sellPrice stores the base price as inc
      incPrice: incPrice,
      exPrice: exPrice,
    );
    emit(CartUpdated(cartItems: List.from(_cartItems), selectedCustomer: _selectedCustomer));
  }

  void _onUpdateCartItemSerial(
    UpdateCartItemSerial event,
    Emitter<SalesState> emit,
  ) {
    if (event.index < 0 || event.index >= _cartItems.length) return;

    _cartItems[event.index] = _cartItems[event.index].copyWith(
      serialNumber: event.serialNumber,
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
    _cartItems[event.index] = cartItem.copyWith(
      isEditing: false,
      isNewlyAdded: false,
    );
    
    // Check for low stock warning if the setting is enabled and stock data is available
    LowStockWarning? warning;
    if (event.autoRemindLowStock && cartItem.stock != null) {
      warning = checkLowStockWarning(
        stock: cartItem.stock!,
        saleQty: cartItem.qty,
        autoRemindEnabled: true,
      );
      if (!warning.hasWarning) warning = null;
    }
    
    emit(CartItemSaved(
      index: event.index,
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
      
      // Skip package items as they have fixed pricing
      if (stock.isPackage && stock.sellEx != null && stock.sellInc != null) {
        continue;
      }
      
      // Get effective sell price based on customer grade
      final effectiveResult = stock.getEffectiveSellPrice(customerGrade);
      final double effectiveSell = effectiveResult.price;
      
      double incPrice;
      double exPrice;
      double taxPercentage;
      int taxType;
      
      if (effectiveResult.isPricingGradeApplied) {
        // Pricing grade prices are already inc-tax
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
