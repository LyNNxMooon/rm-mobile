import 'package:json_annotation/json_annotation.dart';
import 'package:rmstock_scanner/entities/response/authenticate_staff_response.dart';

part 'security_groups_response.g.dart';

@JsonSerializable()
class SecurityGroupsResponse {
  final bool success;
  final String message;
  @JsonKey(name: 'shopfrontId')
  final String shopfrontId;
  @JsonKey(name: 'shopfrontName')
  final String shopfrontName;
  @JsonKey(name: 'security_enabled')
  final bool securityEnabled;
  @JsonKey(name: 'group_count')
  final int groupCount;
  final List<SecurityGroup> groups;

  SecurityGroupsResponse({
    required this.success,
    required this.message,
    required this.shopfrontId,
    required this.shopfrontName,
    required this.securityEnabled,
    required this.groupCount,
    required this.groups,
  });

  factory SecurityGroupsResponse.fromJson(Map<String, dynamic> json) =>
      _$SecurityGroupsResponseFromJson(json);
}

@JsonSerializable()
class SecurityGroup {
  @JsonKey(name: 'group_id')
  final int groupId;
  final String name;
  final String abbreviation;
  final String description;
  @JsonKey(name: 'date_modified')
  final String dateModified;
  @JsonKey(name: 'granted_permissions')
  final List<StaffPermission> grantedPermissions;
  @JsonKey(name: 'restricted_permissions')
  final List<StaffPermission> restrictedPermissions;

  SecurityGroup({
    required this.groupId,
    required this.name,
    required this.abbreviation,
    required this.description,
    required this.dateModified,
    required this.grantedPermissions,
    required this.restrictedPermissions,
  });

  factory SecurityGroup.fromJson(Map<String, dynamic> json) =>
      _$SecurityGroupFromJson(json);
}
