import 'package:json_annotation/json_annotation.dart';
part 'discover_response.g.dart';

@JsonSerializable()
class DiscoverResponse {
  final bool isAgent;
  final String agentType;
  final String serverName;
  final String version;
  final int port;
  final String timestamp;

  DiscoverResponse({
    required this.isAgent,
    required this.agentType,
    required this.serverName,
    required this.version,
    required this.port,
    required this.timestamp,
  });

  factory DiscoverResponse.fromJson(Map<String, dynamic> json) =>
      _$DiscoverResponseFromJson(json);
}
