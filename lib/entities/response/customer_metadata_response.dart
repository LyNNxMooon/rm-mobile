import 'package:json_annotation/json_annotation.dart';

part 'customer_metadata_response.g.dart';

@JsonSerializable()
class CustomerMetadataResponse {
  final bool success;
  final String? message;
  @JsonKey(name: 'shopfrontId')
  final String shopfrontId;
  final CustomerMetadata metadata;

  CustomerMetadataResponse({
    required this.success,
    required this.message,
    required this.shopfrontId,
    required this.metadata,
  });

  factory CustomerMetadataResponse.fromJson(Map<String, dynamic> json) =>
      _$CustomerMetadataResponseFromJson(json);
}

@JsonSerializable()
class CustomerMetadata {
  final int count;
  @JsonKey(name: 'minCustomerId')
  final int minCustomerId;
  @JsonKey(name: 'maxCustomerId')
  final int maxCustomerId;
  @JsonKey(name: 'idChecksum')
  final int idChecksum;

  CustomerMetadata({
    required this.count,
    required this.minCustomerId,
    required this.maxCustomerId,
    required this.idChecksum,
  });

  factory CustomerMetadata.fromJson(Map<String, dynamic> json) =>
      _$CustomerMetadataFromJson(json);
}
