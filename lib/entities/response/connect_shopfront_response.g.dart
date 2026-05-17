// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'connect_shopfront_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ConnectShopfrontResponse _$ConnectShopfrontResponseFromJson(
        Map<String, dynamic> json) =>
    ConnectShopfrontResponse(
      success: json['success'] as bool,
      shopfrontId: json['shopfrontId'] as String,
      shopfrontName: json['shopfrontName'] as String,
      message: json['message'] as String,
      version: json['version'] as String?,
      salesCustom: json['salesCustom'] as String?,
        reminder: json['reminder'] as String?,
      taxCodes: (json['taxCodes'] as List<dynamic>?)
          ?.map((e) => TaxCodeVO.fromJson(e as Map<String, dynamic>))
          .toList(),
      autoChargeSale: json['autoChargeSale'] as bool?,
      autoChargeSaleStock: (json['autoChargeSaleStock'] as num?)?.toInt(),
      autoChargeSalePercent: (json['autoChargeSalePercent'] as num?)?.toInt(),
    );

Map<String, dynamic> _$ConnectShopfrontResponseToJson(
        ConnectShopfrontResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'shopfrontId': instance.shopfrontId,
      'shopfrontName': instance.shopfrontName,
      'message': instance.message,
      'version': instance.version,
      'salesCustom': instance.salesCustom,
      'reminder': instance.reminder,
      'taxCodes': instance.taxCodes,
      'autoChargeSale': instance.autoChargeSale,
      'autoChargeSaleStock': instance.autoChargeSaleStock,
      'autoChargeSalePercent': instance.autoChargeSalePercent,
    };
