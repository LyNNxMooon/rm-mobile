import 'package:json_annotation/json_annotation.dart';

part 'stock_activity_response.g.dart';

@JsonSerializable()
class StockActivityResponse {
  final bool success;
  final String? message;
  @JsonKey(name: 'shopfront_id')
  final String? shopfrontId;
  @JsonKey(name: 'stock_id')
  final int? stockId;
  final List<StockActivityItem>? activities;

  StockActivityResponse({
    required this.success,
    this.message,
    this.shopfrontId,
    this.stockId,
    this.activities,
  });

  factory StockActivityResponse.fromJson(Map<String, dynamic> json) =>
      _$StockActivityResponseFromJson(json);

  Map<String, dynamic> toJson() => _$StockActivityResponseToJson(this);
}

@JsonSerializable()
class StockActivityItem {
  @JsonKey(name: 'stock_id')
  final int stockId;
  final String transaction;
  @JsonKey(name: 'transaction_desc')
  final String transactionDesc;
  @JsonKey(name: 'tran_id')
  final int tranId;
  @JsonKey(name: 'last_date')
  final String lastDate;
  final num quantity;

  StockActivityItem({
    required this.stockId,
    required this.transaction,
    required this.transactionDesc,
    required this.tranId,
    required this.lastDate,
    required this.quantity,
  });

  factory StockActivityItem.fromJson(Map<String, dynamic> json) =>
      _$StockActivityItemFromJson(json);

  Map<String, dynamic> toJson() => _$StockActivityItemToJson(this);
}
