// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'last_sold_price_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LastSoldPriceResponse _$LastSoldPriceResponseFromJson(
        Map<String, dynamic> json) =>
    LastSoldPriceResponse(
      success: json['success'] as bool,
      message: json['message'] as String?,
      stockId: (json['stock_id'] as num).toInt(),
      lastSoldPrice: (json['last_sold_price'] as num?)?.toDouble(),
    );
