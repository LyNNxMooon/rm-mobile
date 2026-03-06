import 'package:json_annotation/json_annotation.dart';

part 'customer_lookup_api_response.g.dart';

@JsonSerializable()
class CustomerLookupApiResponse {
  final bool success;
  final String message;
  final String shopfrontId;
  final String shopfrontName;
  final String syncTimestamp;
  final bool isDeltaSync;
  final int totalItems;
  final int itemCount;
  final int totalPages;
  final bool hasMore;
  final int? lastCustomerId;
  final List<Map<String, dynamic>> items;

  CustomerLookupApiResponse({
    required this.success,
    required this.message,
    required this.shopfrontId,
    required this.shopfrontName,
    required this.syncTimestamp,
    required this.isDeltaSync,
    required this.totalItems,
    required this.itemCount,
    required this.totalPages,
    required this.hasMore,
    required this.lastCustomerId,
    required this.items,
  });

  factory CustomerLookupApiResponse.fromJson(Map<String, dynamic> json) =>
      _$CustomerLookupApiResponseFromJson(json);
}
