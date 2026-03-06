// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pair_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PairResponse _$PairResponseFromJson(Map<String, dynamic> json) => PairResponse(
      success: json['success'] as bool,
      apiKey: json['apiKey'] as String,
      deviceId: json['deviceId'] as String,
      message: json['message'] as String,
      expiresAt: json['expiresAt'] as String?,
    );

Map<String, dynamic> _$PairResponseToJson(PairResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'apiKey': instance.apiKey,
      'deviceId': instance.deviceId,
      'message': instance.message,
      'expiresAt': instance.expiresAt,
    };
