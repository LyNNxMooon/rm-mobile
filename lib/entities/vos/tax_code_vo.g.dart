// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tax_code_vo.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TaxCodeVO _$TaxCodeVOFromJson(Map<String, dynamic> json) => TaxCodeVO(
      code: json['code'] as String,
      export: json['export'] as String,
      description: json['description'] as String,
      percentage: (json['percentage'] as num).toDouble(),
      taxType: (json['tax_type'] as num).toInt(),
      salesAc: json['sales_ac'] as String,
      goodsAc: json['goods_ac'] as String,
      taxId: (json['tax_id'] as num).toInt(),
      dateModified: json['date_modified'] as String,
    );

Map<String, dynamic> _$TaxCodeVOToJson(TaxCodeVO instance) => <String, dynamic>{
      'code': instance.code,
      'export': instance.export,
      'description': instance.description,
      'percentage': instance.percentage,
      'tax_type': instance.taxType,
      'sales_ac': instance.salesAc,
      'goods_ac': instance.goodsAc,
      'tax_id': instance.taxId,
      'date_modified': instance.dateModified,
    };
