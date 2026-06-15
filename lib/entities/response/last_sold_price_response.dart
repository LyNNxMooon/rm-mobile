import 'package:json_annotation/json_annotation.dart';

part 'last_sold_price_response.g.dart';

@JsonSerializable()
class LastSoldPriceResponse {
  final bool success;
  final String? message;
  @JsonKey(name: 'stock_id')
  final int stockId;
  @JsonKey(name: 'last_sold_price')
  final double? lastSoldPrice;

  LastSoldPriceResponse({
    required this.success,
    required this.message,
    required this.stockId,
    this.lastSoldPrice,
  });

  factory LastSoldPriceResponse.fromJson(Map<String, dynamic> json) =>
      _$LastSoldPriceResponseFromJson(json);
}
