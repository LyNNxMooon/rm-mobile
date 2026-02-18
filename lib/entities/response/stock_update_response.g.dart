// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: unused_element

part of 'stock_update_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StockUpdateResponse _$StockUpdateResponseFromJson(Map<String, dynamic> json) =>
    StockUpdateResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
      updated: (json['updated'] as num).toInt(),
      missing: (json['missing'] as num).toInt(),
      skipped: (json['skipped'] as num).toInt(),
    );

Map<String, dynamic> _$StockUpdateResponseToJson(
  StockUpdateResponse instance,
) => <String, dynamic>{
  'success': instance.success,
  'message': instance.message,
  'updated': instance.updated,
  'missing': instance.missing,
  'skipped': instance.skipped,
};
