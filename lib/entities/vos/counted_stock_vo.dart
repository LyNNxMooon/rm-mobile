import 'package:json_annotation/json_annotation.dart';
part 'counted_stock_vo.g.dart';

@JsonSerializable()
class CountedStockVO {
  @JsonKey(name: 'stocktake_date')
  final DateTime stocktakeDate;
  @JsonKey(name: 'stock_id')
  final int stockID;
  final int quantity;
  @JsonKey(name: 'date_modified')
  final DateTime dateModified;
  @JsonKey(name: 'is_synced')
  final bool isSynced;
  final String barcode;
  final String description;

  CountedStockVO({
    required this.stocktakeDate,
    required this.stockID,
    required this.quantity,
    required this.dateModified,
    required this.isSynced,
    required this.description,
    required this.barcode,
  });

  factory CountedStockVO.fromJson(Map<String, dynamic> json) =>
      _$CountedStockVOFromJson(json);

  Map<String, dynamic> toJson() => _$CountedStockVOToJson(this);
}
