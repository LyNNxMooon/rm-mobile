import '../../../../entities/vos/cart_item_vo.dart';

/// Use case to validate cart items for out-of-stock conditions
/// Returns a list of cart items where sale quantity exceeds available stock
class ValidateOutOfStockItems {
  /// Check all cart items and return those where sale qty > stock qty
  List<CartItemVO> call({required List<CartItemVO> cartItems}) {
    final outOfStockItems = <CartItemVO>[];
    for (final item in cartItems) {
      if (item.stock != null) {
        final stockQty = item.stock!.quantity;
        if (item.qty > stockQty) {
          outOfStockItems.add(item);
        }
      }
    }
    return outOfStockItems;
  }
}
