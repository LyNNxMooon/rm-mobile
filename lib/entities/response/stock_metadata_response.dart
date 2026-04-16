import 'package:json_annotation/json_annotation.dart';

part 'stock_metadata_response.g.dart';

@JsonSerializable()
class StockMetadataResponse {
  final bool success;
  final String? message;
  @JsonKey(name: 'shopfront_id')
  final String shopfrontId;
  final StockMetadata metadata;

  StockMetadataResponse({
    required this.success,
    required this.message,
    required this.shopfrontId,
    required this.metadata,
  });

  factory StockMetadataResponse.fromJson(Map<String, dynamic> json) =>
      _$StockMetadataResponseFromJson(json);
}

@JsonSerializable()
class StockMetadata {
  final int count;
  @JsonKey(name: 'min_stock_id')
  final int minStockId;
  @JsonKey(name: 'max_stock_id')
  final int maxStockId;
  @JsonKey(name: 'id_checksum')
  final int idChecksum;

  StockMetadata({
    required this.count,
    required this.minStockId,
    required this.maxStockId,
    required this.idChecksum,
  });

  factory StockMetadata.fromJson(Map<String, dynamic> json) =>
      _$StockMetadataFromJson(json);
}
