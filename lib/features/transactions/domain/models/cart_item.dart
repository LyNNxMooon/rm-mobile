/// Model for cart items in Sales transactions.
/// Replace with your actual CartItemVO / StockVO when integrating with API
class CartItem {
  final String code;
  final String description;
  int qty;
  final double sellPrice;
  final double? costPrice;

  CartItem({
    required this.code,
    required this.description,
    this.qty = 1,
    required this.sellPrice,
    this.costPrice,
  });

  double get extension => qty * sellPrice;

  /// Create a copy with updated values
  CartItem copyWith({
    String? code,
    String? description,
    int? qty,
    double? sellPrice,
    double? costPrice,
  }) {
    return CartItem(
      code: code ?? this.code,
      description: description ?? this.description,
      qty: qty ?? this.qty,
      sellPrice: sellPrice ?? this.sellPrice,
      costPrice: costPrice ?? this.costPrice,
    );
  }
}
