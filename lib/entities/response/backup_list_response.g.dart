// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: unused_element

part of 'backup_list_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BackupListItemResponse _$BackupListItemResponseFromJson(
  Map<String, dynamic> json,
) => BackupListItemResponse(
  fileName: json['file_name'] as String,
  sizeBytes: (json['size_bytes'] as num).toInt(),
  lastWriteUtc: json['last_write_utc'] as String,
);

Map<String, dynamic> _$BackupListItemResponseToJson(
  BackupListItemResponse instance,
) => <String, dynamic>{
  'file_name': instance.fileName,
  'size_bytes': instance.sizeBytes,
  'last_write_utc': instance.lastWriteUtc,
};

BackupListResponse _$BackupListResponseFromJson(Map<String, dynamic> json) =>
    BackupListResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
      items: (json['items'] as List<dynamic>)
          .map((e) => BackupListItemResponse.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$BackupListResponseToJson(BackupListResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'items': instance.items,
    };
