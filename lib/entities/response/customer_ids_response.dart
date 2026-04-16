import 'package:json_annotation/json_annotation.dart';

part 'customer_ids_response.g.dart';

@JsonSerializable()
class CustomerIdsResponse {
  final bool success;
  final String? message;
  @JsonKey(name: 'shopfrontId')
  final String shopfrontId;
  @JsonKey(name: 'fromCustomerId')
  final int fromCustomerId;
  @JsonKey(name: 'toCustomerId')
  final int toCustomerId;
  @JsonKey(name: 'customerIds')
  final List<int> customerIds;
  final int count;

  CustomerIdsResponse({
    required this.success,
    required this.message,
    required this.shopfrontId,
    required this.fromCustomerId,
    required this.toCustomerId,
    required this.customerIds,
    required this.count,
  });

  factory CustomerIdsResponse.fromJson(Map<String, dynamic> json) =>
      _$CustomerIdsResponseFromJson(json);
}
