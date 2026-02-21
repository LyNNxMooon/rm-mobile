// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: unused_element

part of 'stocktake_backup_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StocktakeBackupResponse _$StocktakeBackupResponseFromJson(
  Map<String, dynamic> json,
) => StocktakeBackupResponse(
  success: json['success'] as bool,
  message: json['message'] as String,
  fileName: json['file_name'] as String,
  itemCount: (json['item_count'] as num).toInt(),
  savedUtc: json['saved_utc'] as String,
);

Map<String, dynamic> _$StocktakeBackupResponseToJson(
  StocktakeBackupResponse instance,
) => <String, dynamic>{
  'success': instance.success,
  'message': instance.message,
  'file_name': instance.fileName,
  'item_count': instance.itemCount,
  'saved_utc': instance.savedUtc,
};
