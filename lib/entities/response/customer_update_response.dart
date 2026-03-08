import 'package:json_annotation/json_annotation.dart';

part 'customer_update_response.g.dart';

@JsonSerializable()
class CustomerUpdateResponse {
  final bool success;
  final String message;
  final int updated;
  final int missing;
  final int skipped;

  CustomerUpdateResponse({
    required this.success,
    required this.message,
    required this.updated,
    required this.missing,
    required this.skipped,
  });

  factory CustomerUpdateResponse.fromJson(Map<String, dynamic> json) =>
      _$CustomerUpdateResponseFromJson(json);
}
