import 'package:json_annotation/json_annotation.dart';
part 'connect_shopfront_response.g.dart';

@JsonSerializable()
class ConnectShopfrontResponse {
  final bool success;
  final String shopfrontId;
  final String shopfrontName;
  final String message;

  ConnectShopfrontResponse({
    required this.success,
    required this.shopfrontId,
    required this.shopfrontName,
    required this.message,
  });

  factory ConnectShopfrontResponse.fromJson(Map<String, dynamic> json) =>
      _$ConnectShopfrontResponseFromJson(json);
}
