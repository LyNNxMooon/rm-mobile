// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: unused_element

part of 'connect_shopfront_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ConnectShopfrontResponse _$ConnectShopfrontResponseFromJson(
  Map<String, dynamic> json,
) => ConnectShopfrontResponse(
  success: json['success'] as bool,
  shopfrontId: json['shopfrontId'] as String,
  shopfrontName: json['shopfrontName'] as String,
  message: json['message'] as String,
);

Map<String, dynamic> _$ConnectShopfrontResponseToJson(
  ConnectShopfrontResponse instance,
) => <String, dynamic>{
  'success': instance.success,
  'shopfrontId': instance.shopfrontId,
  'shopfrontName': instance.shopfrontName,
  'message': instance.message,
};
