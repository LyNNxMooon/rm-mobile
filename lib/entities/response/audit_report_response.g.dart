// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: unused_element

part of 'audit_report_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AuditReport _$AuditReportFromJson(Map<String, dynamic> json) => AuditReport(
      mobileDeviceId: json['mobile_device_id'] as String,
      mobileDeviceName: json['mobile_device_name'] as String,
      shopfront: json['shopfront'] as String,
      totalStocks: (json['total_stocks'] as num).toInt(),
      data: (json['data'] as List<dynamic>)
          .map((e) => AuditItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$AuditReportToJson(AuditReport instance) =>
    <String, dynamic>{
      'mobile_device_id': instance.mobileDeviceId,
      'mobile_device_name': instance.mobileDeviceName,
      'shopfront': instance.shopfront,
      'total_stocks': instance.totalStocks,
      'data': instance.data,
    };
