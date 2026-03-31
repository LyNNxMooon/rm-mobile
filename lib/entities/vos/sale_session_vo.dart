import 'dart:convert';

import 'cart_item_vo.dart';

/// Value Object for persisted sale sessions.
/// Captures the full state of a sale transaction for later continuation.
class SaleSessionVO {
  final int id;
  final String sessionType; // "Sales", "Account Sale", "Sales Order", "Quote", "Lay-by"
  final String shopfront;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Cart items serialized as JSON
  final List<CartItemData> cartItems;
  
  // Customer data
  final int? customerId;
  final String? customerBarcode;
  final String? customerName;
  
  // Transaction values
  final double subtotal;
  final double discount;
  final Map<String, double> paymentAmounts;
  
  // Additional data
  final String? surveyValue;
  final String? commentValue;

  SaleSessionVO({
    required this.id,
    required this.sessionType,
    required this.shopfront,
    required this.createdAt,
    required this.updatedAt,
    required this.cartItems,
    this.customerId,
    this.customerBarcode,
    this.customerName,
    this.subtotal = 0.0,
    this.discount = 0.0,
    this.paymentAmounts = const {},
    this.surveyValue,
    this.commentValue,
  });

  /// Number of items in cart
  int get itemCount => cartItems.length;

  /// Total quantity across all items
  double get totalQuantity => cartItems.fold(0.0, (sum, item) => sum + item.qty);

  /// Formatted total for display
  String get formattedTotal => '\$${subtotal.toStringAsFixed(2)}';

  /// Create from database row
  factory SaleSessionVO.fromMap(Map<String, dynamic> map) {
    List<CartItemData> items = [];
    if (map['cart_items_json'] != null) {
      final decoded = jsonDecode(map['cart_items_json'] as String) as List;
      items = decoded.map((e) => CartItemData.fromJson(e)).toList();
    }

    Map<String, double> payments = {};
    if (map['payment_amounts_json'] != null) {
      final decoded = jsonDecode(map['payment_amounts_json'] as String) as Map<String, dynamic>;
      payments = decoded.map((k, v) => MapEntry(k, (v as num).toDouble()));
    }

    return SaleSessionVO(
      id: map['id'] as int,
      sessionType: map['session_type'] as String,
      shopfront: map['shopfront'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      cartItems: items,
      customerId: map['customer_id'] as int?,
      customerBarcode: map['customer_barcode'] as String?,
      customerName: map['customer_name'] as String?,
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0.0,
      discount: (map['discount'] as num?)?.toDouble() ?? 0.0,
      paymentAmounts: payments,
      surveyValue: map['survey_value'] as String?,
      commentValue: map['comment_value'] as String?,
    );
  }

  /// Convert to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'session_type': sessionType,
      'shopfront': shopfront,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'cart_items_json': jsonEncode(cartItems.map((e) => e.toJson()).toList()),
      'customer_id': customerId,
      'customer_barcode': customerBarcode,
      'customer_name': customerName,
      'subtotal': subtotal,
      'discount': discount,
      'payment_amounts_json': jsonEncode(paymentAmounts),
      'survey_value': surveyValue,
      'comment_value': commentValue,
    };
  }

  /// Create a copy with updated values
  SaleSessionVO copyWith({
    int? id,
    String? sessionType,
    String? shopfront,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<CartItemData>? cartItems,
    int? customerId,
    String? customerBarcode,
    String? customerName,
    double? subtotal,
    double? discount,
    Map<String, double>? paymentAmounts,
    String? surveyValue,
    String? commentValue,
  }) {
    return SaleSessionVO(
      id: id ?? this.id,
      sessionType: sessionType ?? this.sessionType,
      shopfront: shopfront ?? this.shopfront,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      cartItems: cartItems ?? this.cartItems,
      customerId: customerId ?? this.customerId,
      customerBarcode: customerBarcode ?? this.customerBarcode,
      customerName: customerName ?? this.customerName,
      subtotal: subtotal ?? this.subtotal,
      discount: discount ?? this.discount,
      paymentAmounts: paymentAmounts ?? this.paymentAmounts,
      surveyValue: surveyValue ?? this.surveyValue,
      commentValue: commentValue ?? this.commentValue,
    );
  }
}

/// Simplified cart item data for serialization
class CartItemData {
  final String code;
  final String description;
  final double qty;
  final double sellPrice;
  final double? costPrice;
  final String? serialNumber;
  final int? stockId;

  CartItemData({
    required this.code,
    required this.description,
    required this.qty,
    required this.sellPrice,
    this.costPrice,
    this.serialNumber,
    this.stockId,
  });

  factory CartItemData.fromJson(Map<String, dynamic> json) {
    return CartItemData(
      code: json['code'] as String,
      description: json['description'] as String,
      qty: (json['qty'] as num).toDouble(),
      sellPrice: (json['sell_price'] as num).toDouble(),
      costPrice: (json['cost_price'] as num?)?.toDouble(),
      serialNumber: json['serial_number'] as String?,
      stockId: json['stock_id'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'description': description,
      'qty': qty,
      'sell_price': sellPrice,
      'cost_price': costPrice,
      'serial_number': serialNumber,
      'stock_id': stockId,
    };
  }

  /// Create from CartItemVO
  factory CartItemData.fromCartItem(CartItemVO item) {
    return CartItemData(
      code: item.code,
      description: item.description,
      qty: item.qty,
      sellPrice: item.sellPrice,
      costPrice: item.costPrice,
      serialNumber: item.serialNumber,
      stockId: item.stock?.stockID.toInt(),
    );
  }
}
