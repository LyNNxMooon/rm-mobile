// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'customer_ids_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CustomerIdsResponse _$CustomerIdsResponseFromJson(Map<String, dynamic> json) =>
    CustomerIdsResponse(
      success: json['success'] as bool,
      message: json['message'] as String?,
      shopfrontId: json['shopfrontId'] as String,
      fromCustomerId: (json['fromCustomerId'] as num).toInt(),
      toCustomerId: (json['toCustomerId'] as num).toInt(),
      customerIds: (json['customerIds'] as List<dynamic>)
          .map((e) => (e as num).toInt())
          .toList(),
      count: (json['count'] as num).toInt(),
    );
