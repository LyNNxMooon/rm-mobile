import 'package:json_annotation/json_annotation.dart';
part 'counted_stock_vo.g.dart';

@JsonSerializable()
class CountedStockVO {
  @JsonKey(name: 'stocktake_date')
  final DateTime stocktakeDate;
  @JsonKey(name: 'stock_id')
  final int stockID;
  final num quantity;
  final num inStock;
  @JsonKey(name: 'date_modified')
  final DateTime dateModified;
  final String barcode;
  final String description;
  final String? category1;
  final String? category2;
  final String? category3;

  CountedStockVO({
    required this.inStock,
    required this.stocktakeDate,
    required this.stockID,
    required this.quantity,
    required this.dateModified,
    required this.description,
    required this.barcode,
    this.category1,
    this.category2,
    this.category3,
  });

  factory CountedStockVO.fromJson(Map<String, dynamic> json) =>
      _$CountedStockVOFromJson(json);

  Map<String, dynamic> toJson() => _$CountedStockVOToJson(this);

  static CountedStockVO countedFromHistoryMap(Map<String, dynamic> m) {
    return CountedStockVO(
      stocktakeDate: DateTime.parse(m['stocktake_date'].toString()),
      stockID: (m['stock_id'] as num).toInt(),
      quantity: m['quantity'] as num,
      inStock: m['inStock'] as num,
      dateModified: DateTime.parse(m['date_modified'].toString()),
      description: m['description'].toString(),
      barcode: m['barcode'].toString(),
      category1: m['category1']?.toString(),
      category2: m['category2']?.toString(),
      category3: m['category3']?.toString(),
    );
  }
}
