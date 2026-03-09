// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'customer_create_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CustomerCreateResponse _$CustomerCreateResponseFromJson(
        Map<String, dynamic> json) =>
    CustomerCreateResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
      created: (json['created'] as num).toInt(),
      failed: (json['failed'] as num).toInt(),
      addressesCreated: (json['addressesCreated'] as num).toInt(),
      customerIds: (json['customerIds'] as List<dynamic>)
          .map((e) => (e as num).toInt())
          .toList(),
    );

Map<String, dynamic> _$CustomerCreateResponseToJson(
        CustomerCreateResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'created': instance.created,
      'failed': instance.failed,
      'addressesCreated': instance.addressesCreated,
      'customerIds': instance.customerIds,
    };
