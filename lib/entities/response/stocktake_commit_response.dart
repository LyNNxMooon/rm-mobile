import 'package:json_annotation/json_annotation.dart';

part 'stocktake_commit_response.g.dart';

@JsonSerializable()
class StocktakeCommitResponse {
  final bool success;
  final String message;
  final int inserted;
  final int skipped;

  StocktakeCommitResponse({
    required this.success,
    required this.message,
    required this.inserted,
    required this.skipped,
  });

  factory StocktakeCommitResponse.fromJson(Map<String, dynamic> json) =>
      _$StocktakeCommitResponseFromJson(json);
}
