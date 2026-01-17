// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'counted_stock_vo.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CountedStockVO _$CountedStockVOFromJson(Map<String, dynamic> json) =>
    CountedStockVO(
      stocktakeDate: DateTime.parse(json['stocktake_date'] as String),
      stockID: (json['stock_id'] as num).toInt(),
      quantity: (json['quantity'] as num).toInt(),
      dateModified: DateTime.parse(json['date_modified'] as String),
      isSynced: json['is_synced'] as bool,
      description: json['description'] as String,
      barcode: json['barcode'] as String,
    );

Map<String, dynamic> _$CountedStockVOToJson(CountedStockVO instance) =>
    <String, dynamic>{
      'stocktake_date': instance.stocktakeDate.toIso8601String(),
      'stock_id': instance.stockID,
      'quantity': instance.quantity,
      'date_modified': instance.dateModified.toIso8601String(),
      'is_synced': instance.isSynced,
      'barcode': instance.barcode,
      'description': instance.description,
    };
