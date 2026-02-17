import 'package:json_annotation/json_annotation.dart';
part 'validate_response.g.dart';

@JsonSerializable()
class ValidateResponse {
  final bool success;
  final String? message;

  ValidateResponse({required this.success, this.message});

  factory ValidateResponse.fromJson(Map<String, dynamic> json) =>
      _$ValidateResponseFromJson(json);
}
