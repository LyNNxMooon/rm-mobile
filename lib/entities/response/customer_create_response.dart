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

  factory CustomerCreateResponse.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> safeJson = Map<String, dynamic>.from(json);
    safeJson['created'] = json['created'] ?? 0;
    safeJson['failed'] = json['failed'] ?? 0;
    safeJson['addressesCreated'] = json['addressesCreated'] ?? 0;

    final rawIds = json['customerIds'];
    final List<dynamic> safeIds = rawIds is List
        ? rawIds.where((entry) => entry != null).toList()
        : <dynamic>[];
    safeJson['customerIds'] = safeIds;

    return _$CustomerCreateResponseFromJson(safeJson);
  }
}
