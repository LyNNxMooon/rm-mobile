import 'package:json_annotation/json_annotation.dart';
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

  static bool _asBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final lower = value.toLowerCase();
      return lower == "true" || lower == "1";
    }
    return false;
  }
}
