import 'package:json_annotation/json_annotation.dart';
import '../vos/tax_code_vo.dart';
part 'connect_shopfront_response.g.dart';

@JsonSerializable()
class ConnectShopfrontResponse {
  final bool success;
  final String shopfrontId;
  final String shopfrontName;
  final String message;
  final String? version;
  final String? salesCustom;
  final String? reminder;
  final List<TaxCodeVO>? taxCodes;
  final bool? autoChargeSale;
  final int? autoChargeSaleStock;
  final int? autoChargeSalePercent;

  ConnectShopfrontResponse({
    required this.success,
    required this.shopfrontId,
    required this.shopfrontName,
    required this.message,
    this.version,
    this.salesCustom,
    this.reminder,
    this.taxCodes,
    this.autoChargeSale,
    this.autoChargeSaleStock,
    this.autoChargeSalePercent,
  });

  factory ConnectShopfrontResponse.fromJson(Map<String, dynamic> json) =>
      _$ConnectShopfrontResponseFromJson(json);
}
