// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'customer_update_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CustomerUpdateResponse _$CustomerUpdateResponseFromJson(
        Map<String, dynamic> json) =>
    CustomerUpdateResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
      updated: (json['updated'] as num).toInt(),
      missing: (json['missing'] as num).toInt(),
      skipped: (json['skipped'] as num).toInt(),
    );

Map<String, dynamic> _$CustomerUpdateResponseToJson(
        CustomerUpdateResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'updated': instance.updated,
      'missing': instance.missing,
      'skipped': instance.skipped,
    };
