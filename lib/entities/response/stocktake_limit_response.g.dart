// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: unused_element

part of 'stocktake_limit_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StocktakeLimitResponse _$StocktakeLimitResponseFromJson(
  Map<String, dynamic> json,
) => StocktakeLimitResponse(
  success: json['success'] as bool,
  limit: (json['limit'] as num).toInt(),
  used: (json['used'] as num).toInt(),
  remaining: (json['remaining'] as num).toInt(),
);

Map<String, dynamic> _$StocktakeLimitResponseToJson(
  StocktakeLimitResponse instance,
) => <String, dynamic>{
  'success': instance.success,
  'limit': instance.limit,
  'used': instance.used,
  'remaining': instance.remaining,
};
