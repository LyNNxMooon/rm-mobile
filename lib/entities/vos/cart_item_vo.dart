import 'stock_vo.dart';

/// Value Object for cart items in Sales transactions.
/// Integrated with real StockVO data from local database.
class CartItemVO {
  final String code;
  final String description;
  double qty;
  double sellPrice; // Base sell price from stock (could be ex or inc depending on taxType)
  final double? costPrice;
  final StockVO? stock; // Full stock data for reference
  final String? serialNumber;
  final bool isEditing; // Whether item is in expanded edit mode
  final bool isNewlyAdded; // Whether item was just added (for auto-save logic)
  
  // Tax calculation fields
  final double taxPercentage; // Tax percentage from tax code table
  final int taxType; // 0 or 1 = Ex-tax base, >= 2 = Inc-tax base
  final double incPrice; // Inclusive price (calculated or direct)
  final double exPrice; // Exclusive price (calculated or direct)
  
  // Cost fields (computed with proper tax handling)
  final double computedCostEx;  // Ex-tax cost (from costEx or derived from cost using goods_tax)
  final double computedCostInc; // Inc-tax cost (from costInc or derived from costEx)

  CartItemVO({
    required this.code,
    required this.description,
    this.qty = 1.0,
    required this.sellPrice,
    this.costPrice,
    this.stock,
    this.serialNumber,
    this.isEditing = false,
    this.isNewlyAdded = false,
    this.taxPercentage = 0.0,
    this.taxType = 0,
    double? incPrice,
    double? exPrice,
    this.computedCostEx = 0.0,
    this.computedCostInc = 0.0,
  }) : incPrice = incPrice ?? sellPrice,
       exPrice = exPrice ?? sellPrice;

  /// Extension using inclusive price
  double get extension => qty * incPrice;
  
  /// Extension using exclusive price
  double get extensionEx => qty * exPrice;

  /// Whether this stock item tracks serial numbers
  bool get trackSerial => stock?.trackSerial ?? false;

  /// Create CartItemVO from StockVO
  factory CartItemVO.fromStock(StockVO stock, {double qty = 1.0}) {
    return CartItemVO(
      code: stock.barcode,
      description: stock.description,
      qty: qty,
      sellPrice: stock.sell,
      costPrice: stock.cost,
      stock: stock,
      isEditing: true, // New items start in edit mode
      isNewlyAdded: true, // Mark as newly added for auto-save check
    );
  }

  /// Create a copy with updated values
  CartItemVO copyWith({
    String? code,
    String? description,
    double? qty,
    double? sellPrice,
    double? costPrice,
    StockVO? stock,
    String? serialNumber,
    bool? isEditing,
    bool? isNewlyAdded,
    double? taxPercentage,
    int? taxType,
    double? incPrice,
    double? exPrice,
    double? computedCostEx,
    double? computedCostInc,
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
      isNewlyAdded: isNewlyAdded ?? this.isNewlyAdded,
      taxPercentage: taxPercentage ?? this.taxPercentage,
      taxType: taxType ?? this.taxType,
      incPrice: incPrice ?? this.incPrice,
      exPrice: exPrice ?? this.exPrice,
      computedCostEx: computedCostEx ?? this.computedCostEx,
      computedCostInc: computedCostInc ?? this.computedCostInc,
    );
  }
}
