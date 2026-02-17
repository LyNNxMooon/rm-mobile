import 'package:json_annotation/json_annotation.dart';
part 'paircode_response.g.dart';

@JsonSerializable()
class PaircodeResponse {
  final bool success;
  final String pairingCode;
  final int expiresIn;
  final String message;

  PaircodeResponse({
    required this.success,
    required this.pairingCode,
    required this.expiresIn,
    required this.message,
  });

  factory PaircodeResponse.fromJson(Map<String, dynamic> json) =>
      _$PaircodeResponseFromJson(json);
}
