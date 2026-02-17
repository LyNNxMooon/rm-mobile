// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: unused_element

part of 'paircode_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PaircodeResponse _$PaircodeResponseFromJson(Map<String, dynamic> json) =>
    PaircodeResponse(
      success: json['success'] as bool,
      pairingCode: json['pairingCode'] as String,
      expiresIn: (json['expiresIn'] as num).toInt(),
      message: json['message'] as String,
    );

Map<String, dynamic> _$PaircodeResponseToJson(PaircodeResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'pairingCode': instance.pairingCode,
      'expiresIn': instance.expiresIn,
      'message': instance.message,
    };
