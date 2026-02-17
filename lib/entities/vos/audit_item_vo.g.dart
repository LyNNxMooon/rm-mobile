// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audit_item_vo.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AuditItem _$AuditItemFromJson(Map<String, dynamic> json) => AuditItem(
      auditDate: json['audit_date'] as String,
      tranType: json['tran_type'] as String,
      sourceId: (json['source_id'] as num).toInt(),
      stockId: json['stock_id'] as num,
      movement: (json['movement'] as num).toDouble(),
    );

// ignore: unused_element
Map<String, dynamic> _$AuditItemToJson(AuditItem instance) => <String, dynamic>{
      'audit_date': instance.auditDate,
      'tran_type': instance.tranType,
      'source_id': instance.sourceId,
      'stock_id': instance.stockId,
      'movement': instance.movement,
    };
