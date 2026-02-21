import 'package:json_annotation/json_annotation.dart';
import 'package:rmstock_scanner/entities/vos/backup_stocktake_item_vo.dart';

part 'load_backup_response.g.dart';

@JsonSerializable()
class LoadBackupDataResponse {
  @JsonKey(name: 'mobile_device_id')
  final String mobileDeviceId;
  @JsonKey(name: 'mobile_device_name')
  final String mobileDeviceName;
  final String shopfront;
  @JsonKey(name: 'total_stocks')
  final int totalStocks;
  @JsonKey(name: 'date_started')
  final String dateStarted;
  @JsonKey(name: 'date_ended')
  final String dateEnded;
  final List<BackupStocktakeItemVO> data;

  LoadBackupDataResponse({
    required this.mobileDeviceId,
    required this.mobileDeviceName,
    required this.shopfront,
    required this.totalStocks,
    required this.dateStarted,
    required this.dateEnded,
    required this.data,
  });

  factory LoadBackupDataResponse.fromJson(Map<String, dynamic> json) =>
      _$LoadBackupDataResponseFromJson(json);
}

@JsonSerializable()
class LoadBackupResponse {
  final bool success;
  final String message;
  @JsonKey(name: 'file_name')
  final String fileName;
  final LoadBackupDataResponse data;

  LoadBackupResponse({
    required this.success,
    required this.message,
    required this.fileName,
    required this.data,
  });

  factory LoadBackupResponse.fromJson(Map<String, dynamic> json) =>
      _$LoadBackupResponseFromJson(json);
}
