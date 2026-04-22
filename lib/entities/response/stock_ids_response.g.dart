// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stock_ids_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StockIdsResponse _$StockIdsResponseFromJson(Map<String, dynamic> json) =>
    StockIdsResponse(
      success: json['success'] as bool,
      message: json['message'] as String?,
      shopfrontId: json['shopfront_id'] as String,
      fromStockId: (json['from_stock_id'] as num).toInt(),
      toStockId: (json['to_stock_id'] as num).toInt(),
      stockIds:
          (json['stock_ids'] as List<dynamic>).map((e) => (e as num).toInt()).toList(),
      count: (json['count'] as num).toInt(),
    );
