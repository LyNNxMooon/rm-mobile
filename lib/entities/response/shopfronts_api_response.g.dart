// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: unused_element

part of 'shopfronts_api_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ShopfrontsApiResponse _$ShopfrontsApiResponseFromJson(
  Map<String, dynamic> json,
) => ShopfrontsApiResponse(
  success: json['success'] as bool,
  count: (json['count'] as num).toInt(),
  assignedShopfrontId: json['assignedShopfrontId'] as String?,
  shopfronts: (json['shopfronts'] as List<dynamic>)
      .map((e) => ShopfrontApiVO.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$ShopfrontsApiResponseToJson(
  ShopfrontsApiResponse instance,
) => <String, dynamic>{
  'success': instance.success,
  'count': instance.count,
  'assignedShopfrontId': instance.assignedShopfrontId,
  'shopfronts': instance.shopfronts,
};

ShopfrontApiVO _$ShopfrontApiVOFromJson(Map<String, dynamic> json) =>
    ShopfrontApiVO(
      id: json['id'] as String,
      name: json['name'] as String,
      isEnabled: json['isEnabled'] as bool,
      dateAdded: json['dateAdded'] as String,
      isAssigned: json['isAssigned'] as bool,
    );

Map<String, dynamic> _$ShopfrontApiVOToJson(ShopfrontApiVO instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'isEnabled': instance.isEnabled,
      'dateAdded': instance.dateAdded,
      'isAssigned': instance.isAssigned,
    };
