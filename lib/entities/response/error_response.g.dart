// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: unused_element

part of 'error_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ErrorResponse _$ErrorResponseFromJson(Map<String, dynamic> json) =>
    ErrorResponse(
      message: json['message'] as String?,
      error: json['error'] as String?,
      code: json['code'] as String?,
      validationCode: json['validationCode'] as String?,
      validationDetail: json['validationDetail'] as String?,
      used: (json['used'] as num?)?.toInt(),
      limit: (json['limit'] as num?)?.toInt(),
      remaining: (json['remaining'] as num?)?.toInt(),
    );

Map<String, dynamic> _$ErrorResponseToJson(ErrorResponse instance) =>
    <String, dynamic>{
      'message': instance.message,
      'error': instance.error,
      'code': instance.code,
      'validationCode': instance.validationCode,
      'validationDetail': instance.validationDetail,
      'used': instance.used,
      'limit': instance.limit,
      'remaining': instance.remaining,
    };
