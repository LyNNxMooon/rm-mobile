import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../entities/vos/cart_item_vo.dart';
import '../../../../entities/vos/customer_vo.dart';
import '../../../../entities/vos/stock_vo.dart';
import '../../domain/models/low_stock_warning.dart';
import '../../domain/use_cases/search_stock_for_sale.dart';
import '../../domain/use_cases/search_customer_for_sale.dart';
import '../../domain/use_cases/check_low_stock_warning.dart';
import 'sales_events.dart';
import 'sales_states.dart';

class SalesBloc extends Bloc<SalesEvent, SalesState> {
  final SearchStockForSale searchStockForSale;
  final SearchCustomerForSale searchCustomerForSale;
  final CheckLowStockWarning checkLowStockWarning;
  final List<CartItemVO> _cartItems = [];
  CustomerVO? _selectedCustomer;

  SalesBloc({
    required this.searchStockForSale,
    required this.searchCustomerForSale,
    required this.checkLowStockWarning,
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
        // Auto-add to cart when single match found
        final addedQty = _addStockToCart(result.stock!, skipEditMode: event.skipEditMode);
        
        // Check for low stock warning
        final warning = checkLowStockWarning(
          stock: result.stock!,
          saleQty: addedQty,
          autoRemindEnabled: event.autoRemindLowStock,
        );
        
        emit(CartUpdated(
          cartItems: List.from(_cartItems),
          selectedCustomer: _selectedCustomer,
          lowStockWarning: warning.hasWarning ? warning : null,
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

  void _onSelectStock(SelectStock event, Emitter<SalesState> emit) {
    final addedQty = _addStockToCart(event.stock, skipEditMode: event.skipEditMode);
    
    // Check for low stock warning
    final warning = checkLowStockWarning(
      stock: event.stock,
      saleQty: addedQty,
      autoRemindEnabled: event.autoRemindLowStock,
    );
    
    emit(CartUpdated(
      cartItems: List.from(_cartItems),
      selectedCustomer: _selectedCustomer,
      lowStockWarning: warning.hasWarning ? warning : null,
    ));
  }

  void _onAddToCart(AddToCart event, Emitter<SalesState> emit) {
    final addedQty = _addStockToCart(event.stock, qty: event.qty, skipEditMode: event.skipEditMode);
    
    // Check for low stock warning
    final warning = checkLowStockWarning(
      stock: event.stock,
      saleQty: addedQty,
      autoRemindEnabled: event.autoRemindLowStock,
    );
    
    emit(CartUpdated(
      cartItems: List.from(_cartItems),
      selectedCustomer: _selectedCustomer,
      lowStockWarning: warning.hasWarning ? warning : null,
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
  int _addStockToCart(StockVO stock, {int qty = 1, bool skipEditMode = false}) {
    // Check if item already exists in cart (by barcode)
    final existingIndex = _cartItems.indexWhere(
      (item) => item.code == stock.barcode,
    );

    int totalQty = qty;
    
    if (existingIndex >= 0) {
      // Update quantity of existing item
      totalQty = _cartItems[existingIndex].qty + qty;
      _cartItems[existingIndex] = _cartItems[existingIndex].copyWith(
        qty: totalQty,
        isEditing: skipEditMode ? false : true, // Skip edit mode if auto-adding
      );
    } else {
      // Add new item
      final newItem = CartItemVO.fromStock(stock, qty: qty);
      if (skipEditMode) {
        // Auto-save: don't enter edit mode
        _cartItems.insert(0, newItem.copyWith(isEditing: false, isNewlyAdded: false));
      } else {
        _cartItems.insert(0, newItem);
      }
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

    _cartItems[event.index] = _cartItems[event.index].copyWith(
      sellPrice: event.price,
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

  void _onSelectCustomer(SelectCustomer event, Emitter<SalesState> emit) {
    _selectedCustomer = event.customer;
    emit(CustomerSelected(
      cartItems: List.from(_cartItems),
      selectedCustomer: _selectedCustomer,
    ));
  }

  void _onClearCustomer(ClearCustomer event, Emitter<SalesState> emit) {
    _selectedCustomer = null;
    emit(CartUpdated(
      cartItems: List.from(_cartItems),
      selectedCustomer: null,
    ));
  }
}
