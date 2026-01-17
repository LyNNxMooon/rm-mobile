import 'package:json_annotation/json_annotation.dart';
part 'shopfront_response.g.dart';

@JsonSerializable()
class ShopfrontResponse {
  final int total;
  final List<String> shopfronts;

  ShopfrontResponse({required this.total, required this.shopfronts});

  factory ShopfrontResponse.fromJson(Map<String, dynamic> json) =>
      _$ShopfrontResponseFromJson(json);
}
