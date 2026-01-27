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

  factory StockVO.fromJson(Map<String, dynamic> json) =>
      _$StockVOFromJson(json);

  factory StockVO.fromJsonNetwork(Map<String, dynamic> json) =>
      _$StockVOFromJsonNetwork(json);

  Map<String, dynamic> toJson(String currentShopfront) =>
      _$StockVOToJson(this, currentShopfront);

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
  });
}
