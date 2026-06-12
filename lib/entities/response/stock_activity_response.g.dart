// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stock_activity_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StockActivityResponse _$StockActivityResponseFromJson(
        Map<String, dynamic> json) =>
    StockActivityResponse(
      success: json['success'] as bool,
      message: json['message'] as String?,
      shopfrontId: json['shopfront_id'] as String?,
      stockId: (json['stock_id'] as num?)?.toInt(),
      activities: (json['activities'] as List<dynamic>?)
          ?.map((e) => StockActivityItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$StockActivityResponseToJson(
        StockActivityResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'shopfront_id': instance.shopfrontId,
      'stock_id': instance.stockId,
      'activities': instance.activities,
    };

StockActivityItem _$StockActivityItemFromJson(Map<String, dynamic> json) =>
    StockActivityItem(
      stockId: (json['stock_id'] as num).toInt(),
      transaction: json['transaction'] as String,
      transactionDesc: json['transaction_desc'] as String,
      tranId: (json['tran_id'] as num).toInt(),
      lastDate: json['last_date'] as String,
      quantity: json['quantity'] as num,
    );

Map<String, dynamic> _$StockActivityItemToJson(StockActivityItem instance) =>
    <String, dynamic>{
      'stock_id': instance.stockId,
      'transaction': instance.transaction,
      'transaction_desc': instance.transactionDesc,
      'tran_id': instance.tranId,
      'last_date': instance.lastDate,
      'quantity': instance.quantity,
    };
