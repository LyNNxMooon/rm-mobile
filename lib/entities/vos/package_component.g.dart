// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'package_component.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PackageComponent _$PackageComponentFromJson(Map<String, dynamic> json) =>
    PackageComponent(
      stockId: (json['stock_id'] as num).toInt(),
      quantity: (json['quantity'] as num).toDouble(),
      description: json['description'] as String?,
      barcode: json['barcode'] as String?,
      sellInc: (json['sell_inc'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$PackageComponentToJson(PackageComponent instance) =>
    <String, dynamic>{
      'stock_id': instance.stockId,
      'quantity': instance.quantity,
      'description': instance.description,
      'barcode': instance.barcode,
      'sell_inc': instance.sellInc,
    };
