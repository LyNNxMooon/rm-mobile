// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: unused_element

part of 'stocktake_initcheck_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StocktakeInitcheckResponse _$StocktakeInitcheckResponseFromJson(
  Map<String, dynamic> json,
) => StocktakeInitcheckResponse(
  success: json['success'] as bool,
  message: json['message'] as String,
  shopfrontId: json['shopfrontId'] as String,
  shopfrontName: json['shopfrontName'] as String,
  mobileDeviceId: json['mobile_device_id'] as String,
  mobileDeviceName: json['mobile_device_name'] as String,
  totalStocks: (json['total_stocks'] as num).toInt(),
  data: (json['data'] as List<dynamic>)
      .map((e) => AuditItem.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$StocktakeInitcheckResponseToJson(
  StocktakeInitcheckResponse instance,
) => <String, dynamic>{
  'success': instance.success,
  'message': instance.message,
  'shopfrontId': instance.shopfrontId,
  'shopfrontName': instance.shopfrontName,
  'mobile_device_id': instance.mobileDeviceId,
  'mobile_device_name': instance.mobileDeviceName,
  'total_stocks': instance.totalStocks,
  'data': instance.data,
};
