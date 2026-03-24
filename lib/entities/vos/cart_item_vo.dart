import 'stock_vo.dart';

/// Value Object for cart items in Sales transactions.
/// Integrated with real StockVO data from local database.
class CartItemVO {
  final String code;
  final String description;
  int qty;
  double sellPrice;
  final double? costPrice;
  final StockVO? stock; // Full stock data for reference
  final String? serialNumber;
  final bool isEditing; // Whether item is in expanded edit mode

  CartItemVO({
    required this.code,
    required this.description,
    this.qty = 1,
    required this.sellPrice,
    this.costPrice,
    this.stock,
    this.serialNumber,
    this.isEditing = false,
  });

  double get extension => qty * sellPrice;

  /// Whether this stock item tracks serial numbers
  bool get trackSerial => stock?.trackSerial ?? false;

  /// Create CartItemVO from StockVO
  factory CartItemVO.fromStock(StockVO stock, {int qty = 1}) {
    return CartItemVO(
      code: stock.barcode,
      description: stock.description,
      qty: qty,
      sellPrice: stock.sell,
      costPrice: stock.cost,
      stock: stock,
      isEditing: true, // New items start in edit mode
    );
  }

  /// Create a copy with updated values
  CartItemVO copyWith({
    String? code,
    String? description,
    int? qty,
    double? sellPrice,
    double? costPrice,
    StockVO? stock,
    String? serialNumber,
    bool? isEditing,
  }) {
    return CartItemVO(
      code: code ?? this.code,
      description: description ?? this.description,
      qty: qty ?? this.qty,
      sellPrice: sellPrice ?? this.sellPrice,
      costPrice: costPrice ?? this.costPrice,
      stock: stock ?? this.stock,
      serialNumber: serialNumber ?? this.serialNumber,
      isEditing: isEditing ?? this.isEditing,
    );
  }
}
