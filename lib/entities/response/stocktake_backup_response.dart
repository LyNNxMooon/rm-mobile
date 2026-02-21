import 'package:json_annotation/json_annotation.dart';

part 'stocktake_backup_response.g.dart';

@JsonSerializable()
class StocktakeBackupResponse {
  final bool success;
  final String message;
  @JsonKey(name: 'file_name')
  final String fileName;
  @JsonKey(name: 'item_count')
  final int itemCount;
  @JsonKey(name: 'saved_utc')
  final String savedUtc;

  StocktakeBackupResponse({
    required this.success,
    required this.message,
    required this.fileName,
    required this.itemCount,
    required this.savedUtc,
  });

  factory StocktakeBackupResponse.fromJson(Map<String, dynamic> json) =>
      _$StocktakeBackupResponseFromJson(json);
}
