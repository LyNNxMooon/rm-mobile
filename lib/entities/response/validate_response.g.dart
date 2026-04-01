// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'validate_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ValidateResponse _$ValidateResponseFromJson(Map<String, dynamic> json) =>
    ValidateResponse(
      success: json['success'] as bool,
      deviceId: json['deviceId'] as String?,
      deviceName: json['deviceName'] as String?,
      cashDrawer: json['cashDrawer'] as String?,
      message: json['message'] as String?,
    );

Map<String, dynamic> _$ValidateResponseToJson(ValidateResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'deviceId': instance.deviceId,
      'deviceName': instance.deviceName,
      'cashDrawer': instance.cashDrawer,
      'message': instance.message,
    };
