import 'package:json_annotation/json_annotation.dart';
part 'shopfronts_api_response.g.dart';

@JsonSerializable()
class ShopfrontsApiResponse {
  final bool success;
  final int count;
  final String? assignedShopfrontId;
  final List<ShopfrontApiVO> shopfronts;

  ShopfrontsApiResponse({
    required this.success,
    required this.count,
    required this.assignedShopfrontId,
    required this.shopfronts,
  });

  factory ShopfrontsApiResponse.fromJson(Map<String, dynamic> json) =>
      _$ShopfrontsApiResponseFromJson(json);
}

@JsonSerializable()
class ShopfrontApiVO {
  final String id;
  final String name;
  final bool isEnabled;
  final String dateAdded;
  final bool isAssigned;

  ShopfrontApiVO({
    required this.id,
    required this.name,
    required this.isEnabled,
    required this.dateAdded,
    required this.isAssigned,
  });

  factory ShopfrontApiVO.fromJson(Map<String, dynamic> json) =>
      _$ShopfrontApiVOFromJson(json);
}
