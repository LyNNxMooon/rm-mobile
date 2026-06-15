import 'package:decimal/decimal.dart';
import 'package:rational/rational.dart';

import 'serial_number_vo.dart';
import 'stock_vo.dart';

/// Status of the last-sold-price lookup for a cart item.
enum LastSoldPriceStatus { none, loading, loaded, failed }

/// Value Object for cart items in Sales transactions.
/// Integrated with real StockVO data from local database.
class CartItemVO {
  final String code;
  final String description;
  double qty;
  double sellPrice; // Base sell price from stock (could be ex or inc depending on taxType)
  final double? costPrice;
  final StockVO? stock; // Full stock data for reference
  final List<SerialNumberVO> serialNumbers;
  final bool isEditing; // Whether item is in expanded edit mode
  final bool isNewlyAdded; // Whether item was just added (for auto-save logic)
  final bool isPriceOverridden; // Whether price was manually overridden
  
  // Tax calculation fields
  final double taxPercentage; // Tax percentage from tax code table
  final int taxType; // 0 or 1 = Ex-tax base, >= 2 = Inc-tax base
  final double incPrice; // Inclusive price (calculated or direct)
  final double exPrice; // Exclusive price (calculated or direct)
  
  // Cost fields (computed with proper tax handling)
  final double computedCostEx;  // Ex-tax cost (from costEx or derived from cost using goods_tax)
  final double computedCostInc; // Inc-tax cost (from costInc or derived from costEx)

  final double? lastSoldPrice; // Last sold price fetched from server (null if never sold)
  final LastSoldPriceStatus lastSoldPriceStatus; // Lookup state for last sold price

  CartItemVO({
    required this.code,
    required this.description,
    this.qty = 1.0,
    required this.sellPrice,
    this.costPrice,
    this.stock,
    this.serialNumbers = const [],
    this.isEditing = false,
    this.isNewlyAdded = false,
    this.isPriceOverridden = false,
    this.taxPercentage = 0.0,
    this.taxType = 0,
    double? incPrice,
    double? exPrice,
    this.computedCostEx = 0.0,
    this.computedCostInc = 0.0,
    this.lastSoldPrice,
    this.lastSoldPriceStatus = LastSoldPriceStatus.none,
  }) : incPrice = incPrice ?? sellPrice,
       exPrice = exPrice ?? sellPrice;

  /// Extension using inclusive price - calculated with precise Rational arithmetic
  double get extension {
    final qtyRational = Rational.parse(qty.toString());
    final incPriceRational = Rational.parse(incPrice.toString());
    final result = qtyRational * incPriceRational;
    return result.toDecimal(scaleOnInfinitePrecision: 10).toDouble();
  }
  
  /// Extension using exclusive price - calculated with precise Rational arithmetic
  double get extensionEx {
    final qtyRational = Rational.parse(qty.toString());
    final exPriceRational = Rational.parse(exPrice.toString());
    final result = qtyRational * exPriceRational;
    return result.toDecimal(scaleOnInfinitePrecision: 10).toDouble();
  }

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
    List<SerialNumberVO>? serialNumbers,
    bool? isEditing,
    bool? isNewlyAdded,
    bool? isPriceOverridden,
    double? taxPercentage,
    int? taxType,
    double? incPrice,
    double? exPrice,
    double? computedCostEx,
    double? computedCostInc,
    double? lastSoldPrice,
    LastSoldPriceStatus? lastSoldPriceStatus,
  }) {
    return CartItemVO(
      code: code ?? this.code,
      description: description ?? this.description,
      qty: qty ?? this.qty,
      sellPrice: sellPrice ?? this.sellPrice,
      costPrice: costPrice ?? this.costPrice,
      stock: stock ?? this.stock,
      serialNumbers: serialNumbers ?? this.serialNumbers,
      isEditing: isEditing ?? this.isEditing,
      isNewlyAdded: isNewlyAdded ?? this.isNewlyAdded,
      isPriceOverridden: isPriceOverridden ?? this.isPriceOverridden,
      taxPercentage: taxPercentage ?? this.taxPercentage,
      taxType: taxType ?? this.taxType,
      incPrice: incPrice ?? this.incPrice,
      exPrice: exPrice ?? this.exPrice,
      computedCostEx: computedCostEx ?? this.computedCostEx,
      computedCostInc: computedCostInc ?? this.computedCostInc,
      lastSoldPrice: lastSoldPrice ?? this.lastSoldPrice,
      lastSoldPriceStatus: lastSoldPriceStatus ?? this.lastSoldPriceStatus,
    );
  }
}
