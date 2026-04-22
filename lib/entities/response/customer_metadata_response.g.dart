// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'customer_metadata_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CustomerMetadataResponse _$CustomerMetadataResponseFromJson(
        Map<String, dynamic> json) =>
    CustomerMetadataResponse(
      success: json['success'] as bool,
      message: json['message'] as String?,
      shopfrontId: json['shopfrontId'] as String,
      metadata:
          CustomerMetadata.fromJson(json['metadata'] as Map<String, dynamic>),
    );

CustomerMetadata _$CustomerMetadataFromJson(Map<String, dynamic> json) =>
    CustomerMetadata(
      count: (json['count'] as num).toInt(),
      minCustomerId: (json['minCustomerId'] as num).toInt(),
      maxCustomerId: (json['maxCustomerId'] as num).toInt(),
      idChecksum: (json['idChecksum'] as num).toInt(),
    );
