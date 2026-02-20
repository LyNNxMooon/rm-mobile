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
);

Map<String, dynamic> _$StocktakeCommitResponseToJson(
  StocktakeCommitResponse instance,
) => <String, dynamic>{
  'success': instance.success,
  'message': instance.message,
  'inserted': instance.inserted,
  'skipped': instance.skipped,
};
