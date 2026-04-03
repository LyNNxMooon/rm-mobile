import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';
import 'package:rmstock_scanner/entities/vos/pricing_grades.dart';
import 'package:rmstock_scanner/entities/vos/pricing_rules.dart';
import 'package:rmstock_scanner/entities/vos/package_component.dart';
part 'stock_vo.g.dart';

@JsonSerializable()
class StockVO {
  @JsonKey(name: 'stock_id')
  final num stockID;
  @JsonKey(name: 'Barcode')
  final String barcode;
  final String description;
  @JsonKey(name: 'dept_name')
  final String? deptName;
  @JsonKey(name: 'dept_id')
  final int? deptID;
  final String? custom1;
  final String? custom2;
  @JsonKey(name: 'longdesc')
  final String? longDescription;
  final String supplier;
  @JsonKey(name: 'cat1')
  final String? category1;
  @JsonKey(name: 'cat2')
  final String? category2;
  @JsonKey(name: 'cat3')
  final String? category3;
  final double cost;
  final double sell;
  final bool inactive;
  final num quantity;
  @JsonKey(name: 'layby_qty')
  final num laybyQuantity;
  @JsonKey(name: 'salesorder_qty')
  final num salesOrderQuantity;
  @JsonKey(name: 'date_created')
  final String dateCreated;
  @JsonKey(name: 'order_threshold')
  final num orderThreshold;
  @JsonKey(name: 'order_quantity')
  final num orderQuantity;
  @JsonKey(name: 'allow_fractions')
  final bool allowFractions;
  final bool package;
  @JsonKey(name: 'static_quantity')
  final bool staticQuantity;
  @JsonKey(name: 'picture_file_name')
  final String? pictureFileName;
  final String? imageUrl;
  @JsonKey(name: 'goods_tax')
  final String? goodsTax;
  @JsonKey(name: 'sales_tax')
  final String? salesTax;
  @JsonKey(name: 'date_modified')
  final String dateModified;
  final bool freight;
  @JsonKey(name: 'tare_weight')
  final num tareWeight;
  @JsonKey(name: 'unitof_measure')
  final num unitOfMeasure;
  final bool weighted;
  @JsonKey(name: 'track_serial')
  final bool trackSerial;
  @JsonKey(name: 'last_sale_date')
  final String? lastSaleDate;
  @JsonKey(name: 'allow_renaming')
  final bool allowRenaming;
  @JsonKey(
    name: 'pricing_rules',
    fromJson: _pricingRulesFromJson,
    toJson: _pricingRulesToJson,
  )
  final PricingRules? pricingRules;
  @JsonKey(name: 'is_package')
  final bool isPackage;
  @JsonKey(
    name: 'package_components',
    fromJson: _packageComponentsFromJson,
    toJson: _packageComponentsToJson,
  )
  final List<PackageComponent>? packageComponents;
  @JsonKey(name: 'cost_ex')
  final double? costEx;
  @JsonKey(name: 'cost_inc')
  final double? costInc;
  @JsonKey(name: 'sell_ex')
  final double? sellEx;
  @JsonKey(name: 'sell_inc')
  final double? sellInc;
  @JsonKey(
    name: 'pricing_grades_stock',
    fromJson: _pricingGradesFromJson,
    toJson: _pricingGradesToJson,
  )
  final PricingGrades? pricingGradesStock;
  @JsonKey(
    name: 'pricing_grades_categories',
    fromJson: _pricingGradesFromJson,
    toJson: _pricingGradesToJson,
  )
  final PricingGrades? pricingGradesCategories;
  @JsonKey(
    name: 'pricing_grades_global',
    fromJson: _pricingGradesFromJson,
    toJson: _pricingGradesToJson,
  )
  final PricingGrades? pricingGradesGlobal;

  factory StockVO.fromJson(Map<String, dynamic> json) =>
      _$StockVOFromJson(json);

  factory StockVO.fromJsonNetwork(Map<String, dynamic> json) =>
      _$StockVOFromJsonNetwork(json);

  Map<String, dynamic> toJson(String currentShopfront) =>
      _$StockVOToJson(this, currentShopfront);

  factory StockVO.fromApiItem(Map<String, dynamic> item) {
    final mapped = <String, dynamic>{
      "stock_id": _asNum(item["stock_id"]),
      "Barcode": _asString(item["barcode"] ?? item["Barcode"]),
      "description": _asString(item["description"]),
      "dept_name": _asNullableString(item["dept_name"]),
      "dept_id": _asInt(item["dept_id"]),
      "custom1": _asNullableString(item["custom1"]),
      "custom2": _asNullableString(item["custom2"]),
      "longdesc": _asNullableString(item["longdesc"]),
      "supplier": _asString(item["supplier"]),
      "cat1": _asNullableString(item["cat1"]),
      "cat2": _asNullableString(item["cat2"]),
      "cat3": _asNullableString(item["cat3"]),
      "cost": _asNum(item["cost"]),
      "sell": _asNum(item["sell"]),
      "inactive": _asBool(item["inactive"]),
      "quantity": _asNum(item["quantity"]),
      "layby_qty": _asNum(item["layby_qty"]),
      "salesorder_qty": _asNum(item["salesorder_qty"]),
      "date_created": _asString(item["date_created"]),
      "order_threshold": _asNum(item["order_threshold"]),
      "order_quantity": _asNum(item["order_quantity"]),
      "allow_fractions": _asBool(item["allow_fractions"]),
      "package": _asBool(item["package"]),
      "static_quantity": _asBool(item["static_quantity"]),
      "picture_file_name": _asNullableString(item["picture_file_name"]),
      "imageUrl": _asNullableString(
        item["picture_url"] ?? item["thumbnail_url"] ?? item["imageUrl"],
      ),
      "goods_tax": _asNullableString(item["goods_tax"]),
      "sales_tax": _asNullableString(item["sales_tax"]),
      "date_modified": _asString(item["date_modified"]),
      "freight": _asBool(item["freight"]),
      "tare_weight": _asNum(item["tare_weight"]),
      "unitof_measure": _asNum(
        item["unit_of_measure"] ?? item["unitof_measure"],
      ),
      "weighted": _asBool(item["weighted"]),
      "track_serial": _asBool(item["track_serial"]),
      "last_sale_date": _asNullableString(item["last_sale_date"]),
      "allow_renaming": _asBool(item["allow_renaming"]),
      "pricing_rules": item["pricing_rules"],
      "is_package": _asBool(item["is_package"]),
      "package_components": item["package_components"],
      "cost_ex": _asNullableDouble(item["cost_ex"]),
      "cost_inc": _asNullableDouble(item["cost_inc"]),
      "sell_ex": _asNullableDouble(item["sell_ex"]),
      "sell_inc": _asNullableDouble(item["sell_inc"]),
      "pricing_grades_stock": item["pricing_grades_stock"],
      "pricing_grades_categories": item["pricing_grades_categories"],
      "pricing_grades_global": item["pricing_grades_global"],
    };

    return StockVO.fromJsonNetwork(mapped);
  }

  StockVO({
    required this.stockID,
    required this.barcode,
    required this.description,
    required this.deptName,
    required this.deptID,
    required this.custom1,
    required this.custom2,
    required this.longDescription,
    required this.supplier,
    required this.category1,
    required this.category2,
    required this.category3,
    required this.cost,
    required this.sell,
    required this.inactive,
    required this.quantity,
    required this.laybyQuantity,
    required this.salesOrderQuantity,
    required this.dateCreated,
    required this.orderThreshold,
    required this.orderQuantity,
    required this.allowFractions,
    required this.package,
    required this.staticQuantity,
    required this.pictureFileName,
    required this.imageUrl,
    required this.goodsTax,
    required this.salesTax,
    required this.dateModified,
    required this.freight,
    required this.tareWeight,
    required this.unitOfMeasure,
    required this.weighted,
    required this.trackSerial,
    required this.lastSaleDate,
    this.allowRenaming = false,
    this.pricingRules,
    this.isPackage = false,
    this.packageComponents,
    this.costEx,
    this.costInc,
    this.sellEx,
    this.sellInc,
    this.pricingGradesStock,
    this.pricingGradesCategories,
    this.pricingGradesGlobal,
  });

  static String _asString(dynamic value) {
    return value == null ? "" : value.toString();
  }

  static String? _asNullableString(dynamic value) {
    if (value == null) return null;
    final parsed = value.toString();
    return parsed.isEmpty ? null : parsed;
  }

  static int? _asInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static num _asNum(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value;
    final parsed = num.tryParse(value.toString());
    return parsed ?? 0;
  }

  static double? _asNullableDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static bool _asBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final lower = value.toLowerCase();
      return lower == "true" || lower == "1";
    }
    return false;
  }

  static PricingRules? _pricingRulesFromJson(Object? value) {
    if (value == null) return null;
    if (value is PricingRules) return value;
    if (value is Map<String, dynamic>) {
      return PricingRules.fromJson(value);
    }
    if (value is Map) {
      return PricingRules.fromJson(Map<String, dynamic>.from(value));
    }
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return null;
      try {
        final decoded = jsonDecode(trimmed);
        if (decoded is Map<String, dynamic>) {
          return PricingRules.fromJson(decoded);
        }
        if (decoded is Map) {
          return PricingRules.fromJson(Map<String, dynamic>.from(decoded));
        }
      } catch (_) {}
    }
    return null;
  }

  static Object? _pricingRulesToJson(PricingRules? rules) {
    if (rules == null) return null;
    return jsonEncode(rules.toJson());
  }

  static List<PackageComponent>? _packageComponentsFromJson(Object? value) {
    if (value == null) return null;
    if (value is List<PackageComponent>) return value;
    if (value is List) {
      return value
          .map((e) {
            if (e is Map<String, dynamic>) {
              return PackageComponent.fromJson(e);
            }
            if (e is Map) {
              return PackageComponent.fromJson(Map<String, dynamic>.from(e));
            }
            return null;
          })
          .whereType<PackageComponent>()
          .toList();
    }
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return null;
      try {
        final decoded = jsonDecode(trimmed);
        if (decoded is List) {
          return decoded
              .map((e) {
                if (e is Map<String, dynamic>) {
                  return PackageComponent.fromJson(e);
                }
                if (e is Map) {
                  return PackageComponent.fromJson(Map<String, dynamic>.from(e));
                }
                return null;
              })
              .whereType<PackageComponent>()
              .toList();
        }
      } catch (_) {}
    }
    return null;
  }

  static Object? _packageComponentsToJson(List<PackageComponent>? components) {
    if (components == null) return null;
    return jsonEncode(components.map((e) => e.toJson()).toList());
  }

  static PricingGrades? _pricingGradesFromJson(Object? value) {
    if (value == null) return null;
    if (value is PricingGrades) return value;
    if (value is Map<String, dynamic>) {
      return PricingGrades.fromJson(value);
    }
    if (value is Map) {
      return PricingGrades.fromJson(Map<String, dynamic>.from(value));
    }
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return null;
      try {
        final decoded = jsonDecode(trimmed);
        if (decoded is Map<String, dynamic>) {
          return PricingGrades.fromJson(decoded);
        }
        if (decoded is Map) {
          return PricingGrades.fromJson(Map<String, dynamic>.from(decoded));
        }
      } catch (_) {}
    }
    return null;
  }

  static Object? _pricingGradesToJson(PricingGrades? grades) {
    if (grades == null) return null;
    return jsonEncode(grades.toJson());
  }

  /// Returns the effective sell price for a given customer grade,
  /// and whether a pricing grade override was applied.
  /// 
  /// Hierarchy (from lowest to highest priority):
  /// - RRP (sell price) as base
  /// - Global overrides RRP
  /// - Depts/Cats overrides Global
  /// - Stock overrides Depts/Cats
  /// 
  /// Customer grade: 0 = Def, 1 = A, 2 = B, 3 = C, 4 = D
  /// 
  /// Returns a record with:
  /// - price: the effective sell price
  /// - isPricingGradeApplied: true if a pricing grade override was applied
  ///   (price is already inc-tax), false if using base RRP
  ({double price, bool isPricingGradeApplied}) getEffectiveSellPrice(int customerGrade) {
    final String gradeKey = _gradeIntToString(customerGrade);
    double effectivePrice = sell;
    bool pricingGradeApplied = false;
    
    // Apply hierarchy: RRP -> Global -> Categories -> Stock
    final globalPrice = pricingGradesGlobal?.priceForGrade(gradeKey);
    if (globalPrice != null) {
      effectivePrice = globalPrice;
      pricingGradeApplied = true;
    }
    
    final catPrice = pricingGradesCategories?.priceForGrade(gradeKey);
    if (catPrice != null) {
      effectivePrice = catPrice;
      pricingGradeApplied = true;
    }
    
    final stockPrice = pricingGradesStock?.priceForGrade(gradeKey);
    if (stockPrice != null) {
      effectivePrice = stockPrice;
      pricingGradeApplied = true;
    }
    
    return (price: effectivePrice, isPricingGradeApplied: pricingGradeApplied);
  }

  /// Converts customer grade int to grade string key
  static String _gradeIntToString(int grade) {
    switch (grade) {
      case 0:
        return 'Def';
      case 1:
        return 'A';
      case 2:
        return 'B';
      case 3:
        return 'C';
      case 4:
        return 'D';
      default:
        return 'Def';
    }
  }
}