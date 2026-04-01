import 'package:json_annotation/json_annotation.dart';
part 'validate_response.g.dart';

@JsonSerializable()
class ValidateResponse {
  final bool success;
  final String? deviceId;
  final String? deviceName;
  final String? cashDrawer;
  final String? message;

  ValidateResponse({
    required this.success,
    this.deviceId,
    this.deviceName,
    this.cashDrawer,
    this.message,
  });

  factory ValidateResponse.fromJson(Map<String, dynamic> json) =>
      _$ValidateResponseFromJson(json);
}
