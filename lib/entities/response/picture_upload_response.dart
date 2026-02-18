import 'package:json_annotation/json_annotation.dart';

part 'picture_upload_response.g.dart';

@JsonSerializable()
class PictureUploadResponse {
  final bool success;
  final String message;
  @JsonKey(name: 'stock_id')
  final int stockId;
  @JsonKey(name: 'picture_file_name')
  final String pictureFileName;
  @JsonKey(name: 'thumbnail_url')
  final String thumbnailUrl;
  @JsonKey(name: 'picture_url')
  final String pictureUrl;

  PictureUploadResponse({
    required this.success,
    required this.message,
    required this.stockId,
    required this.pictureFileName,
    required this.thumbnailUrl,
    required this.pictureUrl,
  });

  factory PictureUploadResponse.fromJson(Map<String, dynamic> json) =>
      _$PictureUploadResponseFromJson(json);
}
