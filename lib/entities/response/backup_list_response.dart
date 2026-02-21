import 'package:json_annotation/json_annotation.dart';

part 'backup_list_response.g.dart';

@JsonSerializable()
class BackupListItemResponse {
  @JsonKey(name: 'file_name')
  final String fileName;
  @JsonKey(name: 'size_bytes')
  final int sizeBytes;
  @JsonKey(name: 'last_write_utc')
  final String lastWriteUtc;

  BackupListItemResponse({
    required this.fileName,
    required this.sizeBytes,
    required this.lastWriteUtc,
  });

  factory BackupListItemResponse.fromJson(Map<String, dynamic> json) =>
      _$BackupListItemResponseFromJson(json);
}

@JsonSerializable()
class BackupListResponse {
  final bool success;
  final String message;
  final List<BackupListItemResponse> items;

  BackupListResponse({
    required this.success,
    required this.message,
    required this.items,
  });

  factory BackupListResponse.fromJson(Map<String, dynamic> json) =>
      _$BackupListResponseFromJson(json);
}
