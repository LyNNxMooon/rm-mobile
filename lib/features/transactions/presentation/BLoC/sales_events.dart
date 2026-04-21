import '../../../../entities/vos/stock_vo.dart';
import '../../../../entities/vos/customer_vo.dart';
import '../../../../entities/vos/serial_number_vo.dart';

/// Base class for all sales events
abstract class SalesEvent {}

/// Search for stock by barcode, description, custom1, or custom2
class SearchStock extends SalesEvent {
  final String query;
  final bool skipEditMode;
  final bool autoRemindLowStock;
  final bool preventAddIfNoStock;
  SearchStock({
    required this.query,
    this.skipEditMode = false,
    this.autoRemindLowStock = false,
    this.preventAddIfNoStock = false,
  });
}

/// User selected a stock from duplicate matches dialog
class SelectStock extends SalesEvent {
  final StockVO stock;
  final bool skipEditMode;
  final bool autoRemindLowStock;
  final bool preventAddIfNoStock;
  final bool skipFractionalCheck;
  SelectStock({
    required this.stock,
    this.skipEditMode = false,
    this.autoRemindLowStock = false,
    this.preventAddIfNoStock = false,
    this.skipFractionalCheck = false,
  });
}

/// Add stock to cart
class AddToCart extends SalesEvent {
  final StockVO stock;
  final double qty;
  final bool skipEditMode;
  final bool autoRemindLowStock;
  final bool preventAddIfNoStock;
  AddToCart({
    required this.stock,
    this.qty = 1.0,
    this.skipEditMode = false,
    this.autoRemindLowStock = false,
    this.preventAddIfNoStock = false,
  });
}

/// Add a pre-built cart item directly (for session restore)
class AddCartItemDirect extends SalesEvent {
  final dynamic cartItem; // CartItemVO
  AddCartItemDirect({required this.cartItem});
}

/// Update cart item quantity
class UpdateCartItemQty extends SalesEvent {
  final int index;
  final double qty;
  UpdateCartItemQty({required this.index, required this.qty});
}

/// Update cart item sell price
class UpdateCartItemPrice extends SalesEvent {
  final int index;
  final double price;
  final bool isIncPrice; // true = editing Inc price, false = editing Ex price
  UpdateCartItemPrice({required this.index, required this.price, this.isIncPrice = true});
}

/// Update cart item serial number
class UpdateCartItemSerial extends SalesEvent {
  final int index;
  final List<SerialNumberVO> serialNumbers;
  UpdateCartItemSerial({required this.index, required this.serialNumbers});
}

/// Update cart item description (for allow_renaming items)
class UpdateCartItemDescription extends SalesEvent {
  final int index;
  final String description;
  UpdateCartItemDescription({required this.index, required this.description});
}

/// Save cart item (exit edit mode)
class SaveCartItem extends SalesEvent {
  final int index;
  final bool autoRemindLowStock;
  SaveCartItem({required this.index, this.autoRemindLowStock = false});
}

/// Enter edit mode for cart item
class EditCartItem extends SalesEvent {
  final int index;
  EditCartItem({required this.index});
}

/// Remove cart item
class RemoveCartItem extends SalesEvent {
  final int index;
  RemoveCartItem({required this.index});
}

/// Clear all cart items
class ClearCart extends SalesEvent {}

/// Reset search state (e.g., after dialog dismissed)
class ResetSearchState extends SalesEvent {}

// ==================== CUSTOMER EVENTS ====================

/// Search for customer by barcode, name, company, phone, email, etc.
class SearchCustomer extends SalesEvent {
  final String query;
  SearchCustomer({required this.query});
}

/// User selected a customer from duplicate matches dialog
class SelectCustomer extends SalesEvent {
  final CustomerVO customer;
  SelectCustomer({required this.customer});
}

/// Clear selected customer (reset to walk-in)
class ClearCustomer extends SalesEvent {}

/// Recalculate cart prices for a given customer grade
class RecalculatePricesForGrade extends SalesEvent {
  final int grade;
  RecalculatePricesForGrade({required this.grade});
}
