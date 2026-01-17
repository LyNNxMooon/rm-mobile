// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stock_list_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StockListResponse _$StockListResponseFromJson(Map<String, dynamic> json) =>
    StockListResponse(
      totalItems: (json['totalItems'] as num).toInt(),
      data: (json['data'] as List<dynamic>)
          .map((e) => StockVO.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$StockListResponseToJson(StockListResponse instance) =>
    <String, dynamic>{
      'totalItems': instance.totalItems,
      'data': instance.data,
    };
