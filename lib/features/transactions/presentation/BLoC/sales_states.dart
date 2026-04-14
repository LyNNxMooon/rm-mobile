import '../../../../entities/vos/stock_vo.dart';
import '../../../../entities/vos/cart_item_vo.dart';
import '../../../../entities/vos/customer_vo.dart';
import '../../domain/models/low_stock_warning.dart';

/// Base class for all sales states
abstract class SalesState {
  final List<CartItemVO> cartItems;
  final CustomerVO? selectedCustomer;
  final LowStockWarning? lowStockWarning;
  const SalesState({this.cartItems = const [], this.selectedCustomer, this.lowStockWarning});
}

/// Initial state - empty cart
class SalesInitial extends SalesState {
  const SalesInitial() : super(cartItems: const []);
}

/// Stock search is in progress
class StockSearching extends SalesState {
  const StockSearching({required super.cartItems, super.selectedCustomer});
}

/// Single stock found - add to cart
class StockFound extends SalesState {
  final StockVO stock;
  const StockFound({required this.stock, required super.cartItems, super.selectedCustomer});
}

/// Multiple matching stocks found - show selection dialog
class StockDuplicatesFound extends SalesState {
  final List<StockVO> matches;
  const StockDuplicatesFound({required this.matches, required super.cartItems, super.selectedCustomer});
}

/// Stock not found
class StockNotFound extends SalesState {
  final String message;
  const StockNotFound({required this.message, required super.cartItems, super.selectedCustomer});
}

/// Error during search
class StockSearchError extends SalesState {
  final String error;
  const StockSearchError({required this.error, required super.cartItems, super.selectedCustomer});
}

/// Stock cannot be added - insufficient quantity
class StockNotPermitted extends SalesState {
  final String message;
  const StockNotPermitted({required this.message, required super.cartItems, super.selectedCustomer});
}

/// Fractional item found - needs special handling based on settings
class FractionalItemFound extends SalesState {
  final StockVO stock;
  const FractionalItemFound({required this.stock, required super.cartItems, super.selectedCustomer});
}

/// Cart updated (item added, removed, or modified)
class CartUpdated extends SalesState {
  final String? message;
  const CartUpdated({
    required super.cartItems,
    this.message,
    super.selectedCustomer,
    super.lowStockWarning,
  });
}

/// Item added with invalid sell price - prompt user to fix
class NegativeSellPriceFound extends SalesState {
  const NegativeSellPriceFound({required super.cartItems, super.selectedCustomer});
}

/// Cart item saved (exited edit mode)
class CartItemSaved extends SalesState {
  final int index;
  const CartItemSaved({
    required this.index,
    required super.cartItems,
    super.selectedCustomer,
    super.lowStockWarning,
  });
}

// ==================== CUSTOMER STATES ====================

/// Customer search is in progress
class CustomerSearching extends SalesState {
  const CustomerSearching({required super.cartItems, super.selectedCustomer});
}

/// Multiple matching customers found - show selection dialog
class CustomerDuplicatesFound extends SalesState {
  final List<CustomerVO> matches;
  const CustomerDuplicatesFound({required this.matches, required super.cartItems, super.selectedCustomer});
}

/// Customer not found
class CustomerNotFound extends SalesState {
  final String message;
  const CustomerNotFound({required this.message, required super.cartItems, super.selectedCustomer});
}

/// Error during customer search
class CustomerSearchError extends SalesState {
  final String error;
  const CustomerSearchError({required this.error, required super.cartItems, super.selectedCustomer});
}

/// Customer selected/updated
class CustomerSelected extends SalesState {
  const CustomerSelected({required super.cartItems, required super.selectedCustomer});
}
