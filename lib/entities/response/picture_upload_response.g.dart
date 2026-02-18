// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: unused_element

part of 'picture_upload_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PictureUploadResponse _$PictureUploadResponseFromJson(
  Map<String, dynamic> json,
) => PictureUploadResponse(
  success: json['success'] as bool,
  message: json['message'] as String,
  stockId: (json['stock_id'] as num).toInt(),
  pictureFileName: json['picture_file_name'] as String,
  thumbnailUrl: json['thumbnail_url'] as String,
  pictureUrl: json['picture_url'] as String,
);

Map<String, dynamic> _$PictureUploadResponseToJson(
  PictureUploadResponse instance,
) => <String, dynamic>{
  'success': instance.success,
  'message': instance.message,
  'stock_id': instance.stockId,
  'picture_file_name': instance.pictureFileName,
  'thumbnail_url': instance.thumbnailUrl,
  'picture_url': instance.pictureUrl,
};
