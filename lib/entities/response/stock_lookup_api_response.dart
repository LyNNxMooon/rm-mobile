import 'package:json_annotation/json_annotation.dart';

part 'stock_lookup_api_response.g.dart';

@JsonSerializable()
class StockLookupApiResponse {
  final bool success;
  final String message;
  final String shopfrontId;
  final String shopfrontName;
  final int page;
  final int totalPages;
  final int totalItems;
  final int itemCount;
  final bool isDeltaSync;
  final String syncTimestamp;
  final List<Map<String, dynamic>> items;
  final int? lastStockId;
  final bool hasMore;

  StockLookupApiResponse({
    required this.success,
    required this.message,
    required this.shopfrontId,
    required this.shopfrontName,
    required this.page,
    required this.totalPages,
    required this.totalItems,
    required this.itemCount,
    required this.isDeltaSync,
    required this.syncTimestamp,
    required this.items,
    required this.lastStockId,
    required this.hasMore,
  });

  factory StockLookupApiResponse.fromJson(Map<String, dynamic> json) =>
      _$StockLookupApiResponseFromJson(json);
}
