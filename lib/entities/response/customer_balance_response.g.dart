// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'customer_balance_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CustomerBalanceResponse _$CustomerBalanceResponseFromJson(
        Map<String, dynamic> json) =>
    CustomerBalanceResponse(
      success: json['success'] as bool? ?? true,
      message: json['message'] as String?,
      shopfrontId: json['shopfrontId'] as String?,
      customerId: (json['customerId'] as num).toInt(),
      owingAmount: json['owingAmount'] as num? ?? 0,
      creditLimit: json['creditLimit'] as num? ?? 0,
      remainingCredit: json['remainingCredit'] as num? ?? 0,
    );
