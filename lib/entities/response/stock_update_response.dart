import 'package:json_annotation/json_annotation.dart';

part 'stock_update_response.g.dart';

@JsonSerializable()
class StockUpdateResponse {
  final bool success;
  final String message;
  final int updated;
  final int missing;
  final int skipped;

  StockUpdateResponse({
    required this.success,
    required this.message,
    required this.updated,
    required this.missing,
    required this.skipped,
  });

  factory StockUpdateResponse.fromJson(Map<String, dynamic> json) =>
      _$StockUpdateResponseFromJson(json);
}
