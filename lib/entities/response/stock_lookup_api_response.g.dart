// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: unused_element

part of 'stock_lookup_api_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StockLookupApiResponse _$StockLookupApiResponseFromJson(
  Map<String, dynamic> json,
) => StockLookupApiResponse(
  success: json['success'] as bool,
  message: json['message'] as String,
  shopfrontId: json['shopfrontId'] as String,
  shopfrontName: json['shopfrontName'] as String,
  page: (json['page'] as num).toInt(),
  totalPages: (json['totalPages'] as num).toInt(),
  totalItems: (json['totalItems'] as num).toInt(),
  itemCount: (json['itemCount'] as num).toInt(),
  isDeltaSync: json['isDeltaSync'] as bool,
  syncTimestamp: json['syncTimestamp'] as String,
  items: (json['items'] as List<dynamic>)
      .map((e) => Map<String, dynamic>.from(e as Map))
      .toList(),
  lastStockId: (json['lastStockId'] as num?)?.toInt(),
  hasMore: json['hasMore'] as bool,
);

Map<String, dynamic> _$StockLookupApiResponseToJson(
  StockLookupApiResponse instance,
) => <String, dynamic>{
  'success': instance.success,
  'message': instance.message,
  'shopfrontId': instance.shopfrontId,
  'shopfrontName': instance.shopfrontName,
  'page': instance.page,
  'totalPages': instance.totalPages,
  'totalItems': instance.totalItems,
  'itemCount': instance.itemCount,
  'isDeltaSync': instance.isDeltaSync,
  'syncTimestamp': instance.syncTimestamp,
  'items': instance.items,
  'lastStockId': instance.lastStockId,
  'hasMore': instance.hasMore,
};
