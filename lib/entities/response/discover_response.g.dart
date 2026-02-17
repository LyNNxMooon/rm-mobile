// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: unused_element

part of 'discover_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DiscoverResponse _$DiscoverResponseFromJson(Map<String, dynamic> json) =>
    DiscoverResponse(
      isAgent: json['isAgent'] as bool,
      agentType: json['agentType'] as String,
      serverName: json['serverName'] as String,
      version: json['version'] as String,
      port: (json['port'] as num).toInt(),
      timestamp: json['timestamp'] as String,
    );

Map<String, dynamic> _$DiscoverResponseToJson(DiscoverResponse instance) =>
    <String, dynamic>{
      'isAgent': instance.isAgent,
      'agentType': instance.agentType,
      'serverName': instance.serverName,
      'version': instance.version,
      'port': instance.port,
      'timestamp': instance.timestamp,
    };
