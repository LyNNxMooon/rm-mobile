import 'package:json_annotation/json_annotation.dart';

part 'stock_ids_response.g.dart';

@JsonSerializable()
class StockIdsResponse {
  final bool success;
  final String? message;
  @JsonKey(name: 'shopfront_id')
  final String shopfrontId;
  @JsonKey(name: 'from_stock_id')
  final int fromStockId;
  @JsonKey(name: 'to_stock_id')
  final int toStockId;
  @JsonKey(name: 'stock_ids')
  final List<int> stockIds;
  final int count;

  StockIdsResponse({
    required this.success,
    required this.message,
    required this.shopfrontId,
    required this.fromStockId,
    required this.toStockId,
    required this.stockIds,
    required this.count,
  });

  factory StockIdsResponse.fromJson(Map<String, dynamic> json) =>
      _$StockIdsResponseFromJson(json);
}
