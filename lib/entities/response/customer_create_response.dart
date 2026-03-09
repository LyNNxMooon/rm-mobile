import 'package:json_annotation/json_annotation.dart';

part 'customer_create_response.g.dart';

@JsonSerializable()
class CustomerCreateResponse {
  final bool success;
  final String message;
  final int created;
  final int failed;
  final int addressesCreated;
  final List<int> customerIds;

  CustomerCreateResponse({
    required this.success,
    required this.message,
    required this.created,
    required this.failed,
    required this.addressesCreated,
    required this.customerIds,
  });

  factory CustomerCreateResponse.fromJson(Map<String, dynamic> json) =>
      _$CustomerCreateResponseFromJson(json);
}
