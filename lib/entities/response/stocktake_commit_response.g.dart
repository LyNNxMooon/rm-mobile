// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: unused_element

part of 'stocktake_commit_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StocktakeCommitResponse _$StocktakeCommitResponseFromJson(
  Map<String, dynamic> json,
) => StocktakeCommitResponse(
  success: json['success'] as bool,
  message: json['message'] as String,
  inserted: (json['inserted'] as num).toInt(),
  skipped: (json['skipped'] as num).toInt(),
  trialLimit: (json['trial_limit'] as num?)?.toInt(),
  trialUsed: (json['trial_used'] as num?)?.toInt(),
  trialRemaining: (json['trial_remaining'] as num?)?.toInt(),
);

Map<String, dynamic> _$StocktakeCommitResponseToJson(
  StocktakeCommitResponse instance,
) => <String, dynamic>{
  'success': instance.success,
  'message': instance.message,
  'inserted': instance.inserted,
  'skipped': instance.skipped,
  'trial_limit': instance.trialLimit,
  'trial_used': instance.trialUsed,
  'trial_remaining': instance.trialRemaining,
};
