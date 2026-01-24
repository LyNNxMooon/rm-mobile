import 'package:json_annotation/json_annotation.dart';
import 'package:rmstock_scanner/entities/vos/audit_item_vo.dart';
part 'audit_report_response.g.dart';

@JsonSerializable()
class AuditReport {
  @JsonKey(name: 'mobile_device_id')
  final String mobileDeviceId;
  @JsonKey(name: 'mobile_device_name')
  final String mobileDeviceName;
  final String shopfront;
  @JsonKey(name: 'total_stocks')
  final int totalStocks;
  final List<AuditItem> data;

  AuditReport({
    required this.mobileDeviceId,
    required this.mobileDeviceName,
    required this.shopfront,
    required this.totalStocks,
    required this.data,
  });

  factory AuditReport.fromJson(Map<String, dynamic> json) =>
      _$AuditReportFromJson(json);
}
