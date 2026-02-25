import 'package:json_annotation/json_annotation.dart';

part 'stocktake_limit_response.g.dart';

@JsonSerializable()
class StocktakeLimitResponse {
  final bool success;
  final int limit;
  final int used;
  final int remaining;

  StocktakeLimitResponse({
    required this.success,
    required this.limit,
    required this.used,
    required this.remaining,
  });

  factory StocktakeLimitResponse.fromJson(Map<String, dynamic> json) =>
      _$StocktakeLimitResponseFromJson(json);
}
