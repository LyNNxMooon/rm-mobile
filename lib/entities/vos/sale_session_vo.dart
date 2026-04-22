import 'dart:convert';

import 'package:decimal/decimal.dart';
import 'package:intl/intl.dart';
import 'package:rational/rational.dart';

import '../../local_db/local_db_dao.dart';
import '../../utils/tax_calculation_utils.dart';
import 'cart_item_vo.dart';
import 'delivery_info_vo.dart';
import 'serial_number_vo.dart';

/// Value Object for persisted sale sessions.
/// Captures the full state of a sale transaction for later continuation.
class SaleSessionVO {
  final int id;
  final String sessionType; // "Sales", "Account Sale", "Sales Order", "Quote", "Lay-by"
  final String shopfront;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Cart items serialized as JSON (includes both regular and package items)
  // Package items have isPackage=true and packageComponents populated
  final List<CartItemData> cartItems;
  
  // Customer data
  final int? customerId;
  final String? customerBarcode;
  final String? customerName;
  
  // Staff data
  final int? staffId;
  
  // Transaction values
  final double subtotal;
  final double discount;
  final double totalInc;
  final double totalEx;
  final double totalGp; // Total Gross Profit
  final Map<String, double> paymentAmounts;
  
  // Additional data
  final String? surveyValue;
  final String? commentValue;
  final String? drawer; // e.g., "M"
  
  // Delivery Address (only stored when committed in delivery_details_screen)
  final DeliveryAddressData? deliveryAddress;
  
  // Email Audit (only stored when "Email & Commit" is used)
  final EmailAuditData? emailAudit;

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
    this.staffId,
    this.subtotal = 0.0,
    this.discount = 0.0,
    this.totalInc = 0.0,
    this.totalEx = 0.0,
    this.totalGp = 0.0,
    this.paymentAmounts = const {},
    this.surveyValue,
    this.commentValue,
    this.drawer,
    this.deliveryAddress,
    this.emailAudit,
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

    DeliveryAddressData? deliveryAddress;
    if (map['delivery_address_json'] != null) {
      final decoded = jsonDecode(map['delivery_address_json'] as String) as Map<String, dynamic>;
      deliveryAddress = DeliveryAddressData.fromJson(decoded);
    }

    EmailAuditData? emailAudit;
    if (map['email_audit_json'] != null) {
      final decoded = jsonDecode(map['email_audit_json'] as String) as Map<String, dynamic>;
      emailAudit = EmailAuditData.fromJson(decoded);
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
      staffId: map['staff_id'] as int?,
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0.0,
      discount: (map['discount'] as num?)?.toDouble() ?? 0.0,
      totalInc: (map['total_inc'] as num?)?.toDouble() ?? 0.0,
      totalEx: (map['total_ex'] as num?)?.toDouble() ?? 0.0,
      totalGp: (map['total_gp'] as num?)?.toDouble() ?? 0.0,
      paymentAmounts: payments,
      surveyValue: map['survey_value'] as String?,
      commentValue: map['comment_value'] as String?,
      drawer: map['drawer'] as String?,
      deliveryAddress: deliveryAddress,
      emailAudit: emailAudit,
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
      'staff_id': staffId,
      'subtotal': subtotal,
      'discount': discount,
      'total_inc': totalInc,
      'total_ex': totalEx,
      'total_gp': totalGp,
      'payment_amounts_json': jsonEncode(paymentAmounts),
      'survey_value': surveyValue,
      'comment_value': commentValue,
      'drawer': drawer,
      'delivery_address_json': deliveryAddress != null 
          ? jsonEncode(deliveryAddress!.toJson()) 
          : null,
      'email_audit_json': emailAudit != null 
          ? jsonEncode(emailAudit!.toJson()) 
          : null,
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
    int? staffId,
    double? subtotal,
    double? discount,
    double? totalInc,
    double? totalEx,
    double? totalGp,
    Map<String, double>? paymentAmounts,
    String? surveyValue,
    String? commentValue,
    String? drawer,
    DeliveryAddressData? deliveryAddress,
    EmailAuditData? emailAudit,
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
      staffId: staffId ?? this.staffId,
      subtotal: subtotal ?? this.subtotal,
      discount: discount ?? this.discount,
      totalInc: totalInc ?? this.totalInc,
      totalEx: totalEx ?? this.totalEx,
      totalGp: totalGp ?? this.totalGp,
      paymentAmounts: paymentAmounts ?? this.paymentAmounts,
      surveyValue: surveyValue ?? this.surveyValue,
      commentValue: commentValue ?? this.commentValue,
      drawer: drawer ?? this.drawer,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      emailAudit: emailAudit ?? this.emailAudit,
    );
  }
}

/// Simplified cart item data for serialization
class CartItemData {
  final String code;
  final String? description; // Only stored when overridden at POS
  final double qty;
  final List<SerialNumberVO> serialNumbers;
  final int? stockId;
  
  // Price fields
  final double sellInc;  // Inclusive sell price
  final double sellEx;   // Exclusive sell price  
  final double costEx;   // Exclusive cost price
  final double costInc;  // Inclusive cost price
  final double? taxPercentage;
  final int? taxType;
  final double gp;       // Gross Profit: (sellEx - cost) * qty, cost based on taxType
  
  // Additional fields for API payload
  final String? salesTax; // e.g., "GST"
  final double? rrp;
  final int? unitOfMeasure;
  final bool isFreight;
  final bool isStatic;
  final bool isDescriptionOverridden; // Only store description when overridden at POS
  final bool isPackage; // Whether this is a package item
  final bool isPromotion; // Whether item is on promotion (only for normal items, not packages/components)
  final bool isPriceOverridden; // Whether price was manually overridden
  final List<CartItemData>? packageComponents; // Component lines for packages

  CartItemData({
    required this.code,
    this.description,
    required this.qty,
    this.serialNumbers = const [],
    this.stockId,
    required this.sellInc,
    required this.sellEx,
    required this.costEx,
    required this.costInc,
    this.taxPercentage,
    this.taxType,
    this.gp = 0.0,
    this.salesTax,
    this.rrp,
    this.unitOfMeasure,
    this.isFreight = false,
    this.isStatic = false,
    this.isDescriptionOverridden = false,
    this.isPackage = false,
    this.isPromotion = false,
    this.isPriceOverridden = false,
    this.packageComponents,
  });

  factory CartItemData.fromJson(Map<String, dynamic> json) {
    List<CartItemData>? components;
    if (json['package_components'] != null) {
      final decoded = json['package_components'] as List;
      components = decoded.map((e) => CartItemData.fromJson(e as Map<String, dynamic>)).toList();
    }

    final serialNumbers = _serialNumbersFromJson(json);
    
    return CartItemData(
      code: json['code'] as String,
      description: json['description'] as String?,
      qty: (json['qty'] as num).toDouble(),
      serialNumbers: serialNumbers,
      stockId: json['stock_id'] as int?,
      sellInc: (json['sell_inc'] as num?)?.toDouble() ?? 0.0,
      sellEx: (json['sell_ex'] as num?)?.toDouble() ?? 0.0,
      costEx: (json['cost_ex'] as num?)?.toDouble() ?? 0.0,
      costInc: (json['cost_inc'] as num?)?.toDouble() ?? 0.0,
      taxPercentage: (json['tax_percentage'] as num?)?.toDouble(),
      taxType: json['tax_type'] as int?,
      gp: (json['gp'] as num?)?.toDouble() ?? 0.0,
      salesTax: json['sales_tax'] as String?,
      rrp: (json['rrp'] as num?)?.toDouble(),
      unitOfMeasure: (json['unit_of_measure'] as num?)?.toInt(),
      isFreight: json['is_freight'] == true,
      isStatic: json['is_static'] == true,
      isDescriptionOverridden: json['is_description_overridden'] == true,
      isPackage: json['is_package'] == true,
      isPromotion: json['is_promotion'] == true,
      isPriceOverridden: json['is_price_overridden'] == true,
      packageComponents: components,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      if (description != null) 'description': description,
      'qty': qty,
      if (serialNumbers.isNotEmpty)
        'serial_numbers': serialNumbers.map((e) => e.toJson()).toList(),
      'stock_id': stockId,
      'sell_inc': sellInc,
      'sell_ex': sellEx,
      'cost_ex': costEx,
      'cost_inc': costInc,
      'tax_percentage': taxPercentage,
      'tax_type': taxType,
      'gp': gp,
      'sales_tax': salesTax,
      'rrp': rrp,
      'unit_of_measure': unitOfMeasure,
      'is_freight': isFreight,
      'is_static': isStatic,
      'is_description_overridden': isDescriptionOverridden,
      'is_package': isPackage,
      if (isPriceOverridden) 'is_price_overridden': true,
      if (isPromotion) 'is_promotion': isPromotion,
      if (packageComponents != null && packageComponents!.isNotEmpty)
        'package_components': packageComponents!.map((e) => e._toJsonAsComponent()).toList(),
    };
  }

  /// Serialize as a package component (excludes is_package field)
  Map<String, dynamic> _toJsonAsComponent() {
    return {
      'code': code,
      if (description != null) 'description': description,
      'qty': qty,
      if (serialNumbers.isNotEmpty)
        'serial_numbers': serialNumbers.map((e) => e.toJson()).toList(),
      'stock_id': stockId,
      'sell_inc': sellInc,
      'sell_ex': sellEx,
      'cost_ex': costEx,
      'cost_inc': costInc,
      'tax_percentage': taxPercentage,
      'tax_type': taxType,
      'gp': gp,
      'sales_tax': salesTax,
      'rrp': rrp,
      'unit_of_measure': unitOfMeasure,
      'is_freight': isFreight,
      'is_static': isStatic,
      'is_description_overridden': isDescriptionOverridden,
    };
  }

  static List<SerialNumberVO> _serialNumbersFromJson(
    Map<String, dynamic> json,
  ) {
    final rawList = json['serial_numbers'];
    if (rawList is List) {
      return rawList
          .map((item) {
            if (item is SerialNumberVO) return item;
            if (item is Map<String, dynamic>) {
              return SerialNumberVO.fromJson(item);
            }
            if (item is Map) {
              return SerialNumberVO.fromJson(Map<String, dynamic>.from(item));
            }
            return const SerialNumberVO();
          })
          .where((item) => item.number.trim().isNotEmpty || item.serialAuditId != null)
          .toList();
    }

    if (rawList is String && rawList.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(rawList);
        if (decoded is List) {
          return decoded
              .map((item) {
                if (item is Map<String, dynamic>) {
                  return SerialNumberVO.fromJson(item);
                }
                if (item is Map) {
                  return SerialNumberVO.fromJson(Map<String, dynamic>.from(item));
                }
                return const SerialNumberVO();
              })
              .where((item) => item.number.trim().isNotEmpty || item.serialAuditId != null)
              .toList();
        }
      } catch (_) {}
    }

    final legacy = json['serial_number'];
    if (legacy is String && legacy.trim().isNotEmpty) {
      return [SerialNumberVO(number: legacy.trim())];
    }

    return const <SerialNumberVO>[];
  }

  /// Create from CartItemVO (async to lookup goods_tax for costInc calculation)
  static Future<CartItemData> fromCartItemAsync(CartItemVO item, {String? shopfront}) async {
    final stock = item.stock;
    final shop = shopfront ?? '';
    
    // Get cost_ex value with proper tax handling
    double costEx;
    double? costTaxPercentage;
    if (stock?.costEx != null) {
      costEx = stock!.costEx!;
    } else if (stock?.cost != null && stock!.cost > 0) {
      // Look up goods_tax to determine tax_type
      final costTaxResult = await TaxCalculationUtils.calculateCostTax(
        cost: stock.cost,
        goodsTax: stock.goodsTax,
        shopfront: shop,
      );
      costTaxPercentage = costTaxResult.percentage;
      if (costTaxResult.taxType == 0) {
        // tax_type = 0: cost is ex-taxed, use directly
        costEx = stock.cost;
      } else {
        // tax_type != 0: cost is inc-taxed, calculate ex by removing tax
        costEx = costTaxResult.exPrice;
      }
    } else {
      costEx = 0.0;
    }
    
    // Calculate costInc from costEx by directly applying tax percentage
    double costInc = stock?.costInc ?? 0.0;
    if (costInc == 0.0 && costEx > 0) {
      // Get tax percentage if not already fetched
      if (costTaxPercentage == null && stock?.goodsTax != null) {
        final costTaxResult = await TaxCalculationUtils.calculateCostTax(
          cost: costEx,
          goodsTax: stock?.goodsTax,
          shopfront: shop,
        );
        costTaxPercentage = costTaxResult.percentage;
      }
      // Apply tax directly: costInc = costEx * (1 + percentage/100)
      costInc = costTaxPercentage != null && costTaxPercentage > 0
          ? costEx * (1 + costTaxPercentage / 100)
          : costEx;
    }
    
    // RRP is the original inclusive sell price (before promotions/pricing grades)
    double rrp;
    if (stock?.sellInc != null) {
      rrp = stock!.sellInc!;
    } else if (stock?.sell != null && stock!.sell > 0) {
      // Look up sales_tax to determine tax_type
      final sellTaxResult = await TaxCalculationUtils.calculateSellTax(
        sell: stock.sell,
        salesTax: stock.salesTax,
        shopfront: shop,
      );
      if (sellTaxResult.taxType == 0) {
        // tax_type = 0: sell is ex-taxed, apply tax to get inc
        rrp = sellTaxResult.incPrice;
      } else {
        // tax_type != 0: sell is inc-taxed, use directly
        rrp = stock.sell;
      }
    } else {
      rrp = 0.0;
    }
    
    // Build package components if this is a package item
    List<CartItemData>? components;
    if (stock?.isPackage == true && stock?.packageComponents != null) {
      final shop = shopfront ?? '';
      
      // Helper for Rational conversion
      Rational toR(double v) => Rational.parse(v.toString());
      double fromR(Rational r) => r.toDecimal(scaleOnInfinitePrecision: 10).toDouble();
      
      // First pass: collect all component data with pre-calculated values from server
      final List<_ComponentBuildData> componentData = [];
      
      for (final comp in stock!.packageComponents!) {
        // Look up component stock data from database
        final compStock = await LocalDbDAO.instance.getStockById(comp.stockId, shop);
        
        // Use pre-calculated costEx from server, fallback to calculation only if null
        double compCostEx;
        if (compStock?.costEx != null) {
          compCostEx = compStock!.costEx!;
        } else {
          compCostEx = 0.0;
        }
        
        // Use pre-calculated costInc from server, fallback to calculation only if null
        double compCostInc;
        if (compStock?.costInc != null) {
          compCostInc = compStock!.costInc!;
        } else {
          compCostInc = 0.0;
        }
        
        // Use pre-calculated sellInc from server
        double orgSellInc;
        if (comp.sellInc != null) {
          orgSellInc = comp.sellInc!;
        } else if (compStock?.sellInc != null) {
          orgSellInc = compStock!.sellInc!;
        } else {
          orgSellInc = 0.0;
        }
        
        // Get tax info from component stock
        double? compTaxPercentage;
        int? compTaxType;
        if (compStock?.salesTax != null) {
          final sellTaxResult = await TaxCalculationUtils.calculateSellTax(
            sell: orgSellInc,
            salesTax: compStock?.salesTax,
            shopfront: shop,
          );
          compTaxPercentage = sellTaxResult.percentage;
          compTaxType = sellTaxResult.taxType;
        }
        
        // Calculate sell_ex from sell_inc using tax_percentage with Rational precision
        final Rational orgSellExR;
        if (compTaxPercentage != null && compTaxPercentage > 0) {
          // orgSellEx = orgSellInc / (1 + percentage/100)
          final oneHundred = Rational.fromInt(100);
          final taxRateR = toR(compTaxPercentage);
          orgSellExR = toR(orgSellInc) / (Rational.one + taxRateR / oneHundred);
        } else {
          orgSellExR = toR(orgSellInc);
        }
        
        // Component GP for distribution ratio = (sell_ex - cost) * qty using Rational
        // Cost based on taxType
        final costForGpR = toR((compTaxType ?? 0) == 0 ? compCostEx : compCostInc);
        final compGpR = (orgSellExR - costForGpR) * toR(comp.quantity);
        
        componentData.add(_ComponentBuildData(
          comp: comp,
          compStock: compStock,
          orgSellInc: orgSellInc,
          orgSellExR: orgSellExR,
          costEx: compCostEx,
          costInc: compCostInc,
          taxPercentage: compTaxPercentage,
          taxType: compTaxType,
          gpR: compGpR,
          rrp: orgSellInc, // RRP is the original inc sell price before distribution
        ));
      }
      
      // Calculate totals for distribution using Rational
      Rational totalPackageIncR = Rational.zero;
      Rational totalPackageGpR = Rational.zero;
      for (final c in componentData) {
        totalPackageIncR += toR(c.orgSellInc) * toR(c.comp.quantity);
        totalPackageGpR += c.gpR;
      }
      
      // Detect markup/markdown: compare header's actual sell price with sum of components
      final headerSellIncR = toR(item.incPrice);
      final priceDiffR = headerSellIncR - totalPackageIncR; // positive = markup, negative = markdown
      
      // Second pass: apply distribution if there's a pricing adjustment
      components = [];
      for (final data in componentData) {
        Rational newSellIncR = toR(data.orgSellInc);
        Rational newSellExR = data.orgSellExR;
        final baseQtyR = toR(data.comp.quantity);
        final packageQtyR = toR(item.qty);
        final totalQtyR = baseQtyR * packageQtyR; // Component qty * package qty
        final orgSellIncR = toR(data.orgSellInc);
        final orgSellExR = data.orgSellExR;
        
        if (priceDiffR.abs() > Rational.parse('0.001')) { // There's a pricing adjustment
          Rational ratioR;
          
          if (priceDiffR < Rational.zero) {
            // Mark-down (discount)
            final discountR = priceDiffR.abs();
            if (totalPackageGpR > Rational.zero && totalPackageGpR > discountR) {
              // Use GP ratio
              ratioR = totalPackageGpR > Rational.zero ? data.gpR / totalPackageGpR : Rational.zero;
            } else {
              // Use sell_inc ratio
              ratioR = totalPackageIncR > Rational.zero ? (orgSellIncR * baseQtyR) / totalPackageIncR : Rational.zero;
            }
            final comLineDiscountR = discountR * ratioR;
            newSellIncR = orgSellIncR - (comLineDiscountR / baseQtyR);
          } else {
            // Mark-up
            final markupR = priceDiffR;
            if (totalPackageGpR > Rational.zero) {
              // Use GP ratio
              ratioR = data.gpR / totalPackageGpR;
            } else {
              // Use sell_inc ratio
              ratioR = totalPackageIncR > Rational.zero ? (orgSellIncR * baseQtyR) / totalPackageIncR : Rational.zero;
            }
            final comLineShareR = markupR * ratioR;
            newSellIncR = orgSellIncR + (comLineShareR / baseQtyR);
          }
          
          // Calculate new_sell_ex maintaining the same ratio
          newSellExR = orgSellIncR > Rational.zero 
              ? newSellIncR * (orgSellExR / orgSellIncR) 
              : newSellIncR;
        }
        
        // Only store description if it differs from stock description
        final compDescOverridden = data.comp.description != null && 
            data.compStock != null && 
            data.comp.description != data.compStock!.description;
        
        // Calculate GP based on taxType using Rational: (newSellEx - cost) * baseQty (per package, not total)
        final compCostForGpR = toR((data.taxType ?? 0) == 0 ? data.costEx : data.costInc);
        final compGpValueR = (newSellExR - compCostForGpR) * baseQtyR;
        
        components.add(CartItemData(
          code: data.comp.barcode ?? '',
          description: compDescOverridden ? data.comp.description : null,
          qty: fromR(totalQtyR), // Component qty * package qty
          stockId: data.comp.stockId,
          sellInc: fromR(newSellIncR),  // Raw precise value
          sellEx: fromR(newSellExR),    // Raw precise value
          costEx: data.costEx,
          costInc: data.costInc,
          taxPercentage: data.taxPercentage,
          taxType: data.taxType,
          gp: fromR(compGpValueR),      // GP per package (not multiplied by package qty)
          salesTax: data.compStock?.salesTax,
          rrp: data.rrp,
          unitOfMeasure: data.compStock?.unitOfMeasure.toInt(),
          isFreight: data.compStock?.freight ?? false,
          isStatic: data.compStock?.staticQuantity ?? false,
          isDescriptionOverridden: compDescOverridden,
        ));
      }
    }
    
    // Only store description if it was overridden at POS
    final isOverridden = item.description != stock?.description;

    final serialNumbers = item.serialNumbers
      .where((serial) => serial.number.trim().isNotEmpty)
      .toList();
    
    // Calculate GP based on taxType from sales_tax:
    // taxType == 0 -> use costEx, taxType != 0 -> use costInc
    final costForGp = item.taxType == 0 ? costEx : costInc;
    final gpValue = (item.exPrice - costForGp) * item.qty;
    
    return CartItemData(
      code: item.code,
      description: isOverridden ? item.description : null,
      qty: item.qty,
      serialNumbers: serialNumbers,
      stockId: stock?.stockID.toInt(),
      sellInc: item.incPrice,
      sellEx: item.exPrice,
      costEx: costEx,
      costInc: costInc,
      taxPercentage: item.taxPercentage,
      taxType: item.taxType,
      gp: gpValue,
      salesTax: stock?.salesTax,
      rrp: rrp,
      unitOfMeasure: stock?.unitOfMeasure.toInt(),
      isFreight: stock?.freight ?? false,
      isStatic: stock?.staticQuantity ?? false,
      isDescriptionOverridden: isOverridden,
      isPackage: stock?.isPackage ?? false,
      isPromotion: stock?.isOnPromotion ?? false,
      isPriceOverridden: item.isPriceOverridden,
      packageComponents: components,
    );
  }
}

/// Helper class for building package components with distribution
class _ComponentBuildData {
  final dynamic comp; // PackageComponent
  final dynamic compStock; // StockVO?
  final double orgSellInc;
  final Rational orgSellExR; // Calculated with Rational precision
  final double costEx;
  final double costInc;
  final double? taxPercentage;
  final int? taxType;
  final Rational gpR; // Used only for distribution ratio calculation (raw precise)
  final double rrp; // Original inclusive sell price
  
  _ComponentBuildData({
    required this.comp,
    required this.compStock,
    required this.orgSellInc,
    required this.orgSellExR,
    required this.costEx,
    required this.costInc,
    this.taxPercentage,
    this.taxType,
    required this.gpR,
    required this.rrp,
  });
}

/// Delivery address data for serialization
/// Only stored when committed in delivery_details_screen
class DeliveryAddressData {
  final String? companyName;
  final String? attention;
  final String? addr1;
  final String? addr2;
  final String? addr3;
  final String? suburb;
  final String? state;
  final String? postcode;
  final String? country;
  final String? phone;
  final String? deliveryDate; // Formatted as "dd/MM/yy @HH:mm"
  final String? comment;

  DeliveryAddressData({
    this.companyName,
    this.attention,
    this.addr1,
    this.addr2,
    this.addr3,
    this.suburb,
    this.state,
    this.postcode,
    this.country,
    this.phone,
    this.deliveryDate,
    this.comment,
  });

  factory DeliveryAddressData.fromJson(Map<String, dynamic> json) {
    return DeliveryAddressData(
      companyName: json['company_name'] as String?,
      attention: json['attention'] as String?,
      addr1: json['addr1'] as String?,
      addr2: json['addr2'] as String?,
      addr3: json['addr3'] as String?,
      suburb: json['suburb'] as String?,
      state: json['state'] as String?,
      postcode: json['postcode'] as String?,
      country: json['country'] as String?,
      phone: json['phone'] as String?,
      deliveryDate: json['delivery_date'] as String?,
      comment: json['comment'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'company_name': companyName,
      'attention': attention,
      'addr1': addr1,
      'addr2': addr2,
      'addr3': addr3,
      'suburb': suburb,
      'state': state,
      'postcode': postcode,
      'country': country,
      'phone': phone,
      'delivery_date': deliveryDate,
      'comment': comment,
    };
  }

  /// Convert to API payload format
  Map<String, dynamic> toApiPayload() {
    return {
      'companyName': companyName ?? '',
      'attention': attention ?? '',
      'addr1': addr1 ?? '',
      'addr2': addr2 ?? '',
      'addr3': addr3 ?? '',
      'suburb': suburb ?? '',
      'state': state ?? '',
      'postcode': postcode ?? '',
      'country': country ?? '',
      'phone': phone ?? '',
      'deliveryDate': deliveryDate ?? '',
      'comment': comment ?? '',
    };
  }

  /// Create from DeliveryInfoVO (used when committing delivery details)
  factory DeliveryAddressData.fromDeliveryInfo(DeliveryInfoVO info, {String? companyName}) {
    // Format delivery date as "dd/MM/yy @HH:mm"
    String? formattedDeliveryDate;
    if (info.deliveryDate != null) {
      formattedDeliveryDate = DateFormat("dd/MM/yy '@'HH:mm").format(info.deliveryDate!);
    }
    
    return DeliveryAddressData(
      companyName: companyName,
      attention: info.recipientName,
      addr1: info.addr1,
      addr2: info.addr2,
      addr3: info.addr3,
      suburb: info.suburb,
      state: info.state,
      postcode: info.postcode,
      country: info.country,
      phone: info.phone.isNotEmpty ? info.phone : info.mobile,
      deliveryDate: formattedDeliveryDate,
      comment: info.notes,
    );
  }

  DeliveryInfoVO toDeliveryInfo({int? customerId}) {
    DateTime? parsedDate;
    if (deliveryDate != null && deliveryDate!.trim().isNotEmpty) {
      try {
        parsedDate = DateFormat("dd/MM/yy '@'HH:mm").parse(deliveryDate!);
      } catch (_) {
        parsedDate = null;
      }
    }

    return DeliveryInfoVO(
      customerId: customerId,
      recipientName: attention ?? '',
      phone: phone ?? '',
      addr1: addr1 ?? '',
      addr2: addr2 ?? '',
      addr3: addr3 ?? '',
      suburb: suburb ?? '',
      state: state ?? '',
      postcode: postcode ?? '',
      country: country ?? '',
      deliveryDate: parsedDate,
      notes: comment ?? '',
      addressSource: 'other',
    );
  }
}

/// Email audit data for serialization
/// Only stored when "Email & Commit" is used
class EmailAuditData {
  final DateTime auditDate;
  final int status; // Always 0
  final String subject; // Always empty
  final String message; // Always empty

  EmailAuditData({
    required this.auditDate,
    this.status = 0,
    this.subject = '',
    this.message = '',
  });

  factory EmailAuditData.fromJson(Map<String, dynamic> json) {
    return EmailAuditData(
      auditDate: DateTime.parse(json['audit_date'] as String),
      status: json['status'] as int? ?? 0,
      subject: json['subject'] as String? ?? '',
      message: json['message'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'audit_date': auditDate.toIso8601String(),
      'status': status,
      'subject': subject,
      'message': message,
    };
  }

  /// Convert to API payload format
  Map<String, dynamic> toApiPayload() {
    return {
      'auditDate': auditDate.toIso8601String(),
      'status': status,
      'subject': subject,
      'message': message,
    };
  }
}
