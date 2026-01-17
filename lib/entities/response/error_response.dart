
import 'package:json_annotation/json_annotation.dart';
part 'error_response.g.dart';

@JsonSerializable()
class ErrorResponse {
  final String message;

  ErrorResponse({required this.message});

  factory ErrorResponse.fromJson(Map<String, dynamic> json) =>
      _$ErrorResponseFromJson(json);
}