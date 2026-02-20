import 'package:json_annotation/json_annotation.dart';
import 'package:rmstock_scanner/entities/vos/audit_item_vo.dart';

part 'stocktake_initcheck_response.g.dart';

@JsonSerializable()
class StocktakeInitcheckResponse {
  final bool success;
  final String message;
  @JsonKey(name: 'shopfrontId')
  final String shopfrontId;
  @JsonKey(name: 'shopfrontName')
  final String shopfrontName;
  @JsonKey(name: 'mobile_device_id')
  final String mobileDeviceId;
  @JsonKey(name: 'mobile_device_name')
  final String mobileDeviceName;
  @JsonKey(name: 'total_stocks')
  final int totalStocks;
  final List<AuditItem> data;

  StocktakeInitcheckResponse({
    required this.success,
    required this.message,
    required this.shopfrontId,
    required this.shopfrontName,
    required this.mobileDeviceId,
    required this.mobileDeviceName,
    required this.totalStocks,
    required this.data,
  });

  factory StocktakeInitcheckResponse.fromJson(Map<String, dynamic> json) =>
      _$StocktakeInitcheckResponseFromJson(json);
}
