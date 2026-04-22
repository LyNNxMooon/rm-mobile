// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stock_metadata_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StockMetadataResponse _$StockMetadataResponseFromJson(
        Map<String, dynamic> json) =>
    StockMetadataResponse(
      success: json['success'] as bool,
      message: json['message'] as String?,
      shopfrontId: json['shopfront_id'] as String,
      metadata: StockMetadata.fromJson(json['metadata'] as Map<String, dynamic>),
    );

StockMetadata _$StockMetadataFromJson(Map<String, dynamic> json) =>
    StockMetadata(
      count: (json['count'] as num).toInt(),
      minStockId: (json['min_stock_id'] as num).toInt(),
      maxStockId: (json['max_stock_id'] as num).toInt(),
      idChecksum: (json['id_checksum'] as num).toInt(),
    );
