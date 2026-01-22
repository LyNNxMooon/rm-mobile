// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shopfront_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ShopfrontResponse _$ShopfrontResponseFromJson(Map<String, dynamic> json) =>
    ShopfrontResponse(
      total: (json['total'] as num).toInt(),
      shopfronts: (json['shopfronts'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );

// Map<String, dynamic> _$ShopfrontResponseToJson(ShopfrontResponse instance) =>
//     <String, dynamic>{
//       'total': instance.total,
//       'shopfronts': instance.shopfronts,
//     };
