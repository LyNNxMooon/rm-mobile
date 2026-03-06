// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'customer_lookup_api_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CustomerLookupApiResponse _$CustomerLookupApiResponseFromJson(
        Map<String, dynamic> json) =>
    CustomerLookupApiResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
      shopfrontId: json['shopfrontId'] as String,
      shopfrontName: json['shopfrontName'] as String,
      syncTimestamp: json['syncTimestamp'] as String,
      isDeltaSync: json['isDeltaSync'] as bool,
      totalItems: (json['totalItems'] as num).toInt(),
      itemCount: (json['itemCount'] as num).toInt(),
      totalPages: (json['totalPages'] as num).toInt(),
      hasMore: json['hasMore'] as bool,
      lastCustomerId: (json['lastCustomerId'] as num?)?.toInt(),
      items: (json['items'] as List<dynamic>)
          .map((e) => e as Map<String, dynamic>)
          .toList(),
    );

Map<String, dynamic> _$CustomerLookupApiResponseToJson(
        CustomerLookupApiResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'shopfrontId': instance.shopfrontId,
      'shopfrontName': instance.shopfrontName,
      'syncTimestamp': instance.syncTimestamp,
      'isDeltaSync': instance.isDeltaSync,
      'totalItems': instance.totalItems,
      'itemCount': instance.itemCount,
      'totalPages': instance.totalPages,
      'hasMore': instance.hasMore,
      'lastCustomerId': instance.lastCustomerId,
      'items': instance.items,
    };
