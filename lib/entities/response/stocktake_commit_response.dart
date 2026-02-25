import 'package:json_annotation/json_annotation.dart';

part 'stocktake_commit_response.g.dart';

@JsonSerializable()
class StocktakeCommitResponse {
  final bool success;
  final String message;
  final int inserted;
  final int skipped;
  @JsonKey(name: 'trial_limit')
  final int? trialLimit;
  @JsonKey(name: 'trial_used')
  final int? trialUsed;
  @JsonKey(name: 'trial_remaining')
  final int? trialRemaining;

  StocktakeCommitResponse({
    required this.success,
    required this.message,
    required this.inserted,
    required this.skipped,
    this.trialLimit,
    this.trialUsed,
    this.trialRemaining,
  });

  factory StocktakeCommitResponse.fromJson(Map<String, dynamic> json) =>
      _$StocktakeCommitResponseFromJson(json);
}
