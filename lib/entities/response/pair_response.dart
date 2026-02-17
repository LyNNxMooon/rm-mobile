import 'package:json_annotation/json_annotation.dart';
part 'pair_response.g.dart';

@JsonSerializable()
class PairResponse {
  final bool success;
  final String apiKey;
  final String deviceId;
  final String message;
  final String? expiresAt;

  PairResponse({
    required this.success,
    required this.apiKey,
    required this.deviceId,
    required this.message,
    required this.expiresAt,
  });

  factory PairResponse.fromJson(Map<String, dynamic> json) =>
      _$PairResponseFromJson(json);
}
