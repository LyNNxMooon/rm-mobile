// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: unused_element

part of 'load_backup_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LoadBackupDataResponse _$LoadBackupDataResponseFromJson(
  Map<String, dynamic> json,
) => LoadBackupDataResponse(
  mobileDeviceId: json['mobile_device_id'] as String,
  mobileDeviceName: json['mobile_device_name'] as String,
  shopfront: json['shopfront'] as String,
  totalStocks: (json['total_stocks'] as num).toInt(),
  dateStarted: json['date_started'] as String,
  dateEnded: json['date_ended'] as String,
  data: (json['data'] as List<dynamic>)
      .map((e) => BackupStocktakeItemVO.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$LoadBackupDataResponseToJson(
  LoadBackupDataResponse instance,
) => <String, dynamic>{
  'mobile_device_id': instance.mobileDeviceId,
  'mobile_device_name': instance.mobileDeviceName,
  'shopfront': instance.shopfront,
  'total_stocks': instance.totalStocks,
  'date_started': instance.dateStarted,
  'date_ended': instance.dateEnded,
  'data': instance.data,
};

LoadBackupResponse _$LoadBackupResponseFromJson(Map<String, dynamic> json) =>
    LoadBackupResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
      fileName: json['file_name'] as String,
      data: LoadBackupDataResponse.fromJson(json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$LoadBackupResponseToJson(LoadBackupResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'file_name': instance.fileName,
      'data': instance.data,
    };
