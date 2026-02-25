import 'package:json_annotation/json_annotation.dart';
part 'error_response.g.dart';

@JsonSerializable()
class ErrorResponse {
  final String? message;
  final String? error;
  final String? code;
  @JsonKey(name: 'validationCode')
  final String? validationCode;
  @JsonKey(name: 'validationDetail')
  final String? validationDetail;
  final int? used;
  final int? limit;
  final int? remaining;

  ErrorResponse({
    this.message,
    this.error,
    this.code,
    this.validationCode,
    this.validationDetail,
    this.used,
    this.limit,
    this.remaining,
  });

  String get mainMessage {
    final msg = error?.trim();
    if (msg != null && msg.isNotEmpty) return msg;
    final fallback = message?.trim();
    if (fallback != null && fallback.isNotEmpty) return fallback;
    return "Unknown error occurred.";
  }

  factory ErrorResponse.fromJson(Map<String, dynamic> json) =>
      _$ErrorResponseFromJson(json);
}
