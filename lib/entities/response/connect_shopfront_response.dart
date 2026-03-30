import 'package:json_annotation/json_annotation.dart';
import '../vos/tax_code_vo.dart';
part 'connect_shopfront_response.g.dart';

@JsonSerializable()
class ConnectShopfrontResponse {
  final bool success;
  final String shopfrontId;
  final String shopfrontName;
  final String message;
  final String? salesCustom;
  final List<TaxCodeVO>? taxCodes;

  ConnectShopfrontResponse({
    required this.success,
    required this.shopfrontId,
    required this.shopfrontName,
    required this.message,
    this.salesCustom,
    this.taxCodes,
  });

  factory ConnectShopfrontResponse.fromJson(Map<String, dynamic> json) =>
      _$ConnectShopfrontResponseFromJson(json);
}
