// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: unused_element

part of 'security_groups_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SecurityGroupsResponse _$SecurityGroupsResponseFromJson(
  Map<String, dynamic> json,
) => SecurityGroupsResponse(
  success: json['success'] as bool,
  message: json['message'] as String,
  shopfrontId: json['shopfrontId'] as String,
  shopfrontName: json['shopfrontName'] as String,
  securityEnabled: json['security_enabled'] as bool,
  groupCount: (json['group_count'] as num).toInt(),
  groups:
      (json['groups'] as List<dynamic>?)
          ?.map((e) => SecurityGroup.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <SecurityGroup>[],
);

Map<String, dynamic> _$SecurityGroupsResponseToJson(
  SecurityGroupsResponse instance,
) => <String, dynamic>{
  'success': instance.success,
  'message': instance.message,
  'shopfrontId': instance.shopfrontId,
  'shopfrontName': instance.shopfrontName,
  'security_enabled': instance.securityEnabled,
  'group_count': instance.groupCount,
  'groups': instance.groups,
};

SecurityGroup _$SecurityGroupFromJson(Map<String, dynamic> json) =>
    SecurityGroup(
      groupId: (json['group_id'] as num).toInt(),
      name: json['name'] as String,
      abbreviation: json['abbreviation'] as String,
      description: json['description'] as String,
      dateModified: json['date_modified'] as String,
      grantedPermissions:
          (json['granted_permissions'] as List<dynamic>?)
              ?.map((e) => StaffPermission.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <StaffPermission>[],
      restrictedPermissions:
          (json['restricted_permissions'] as List<dynamic>?)
              ?.map((e) => StaffPermission.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <StaffPermission>[],
    );

Map<String, dynamic> _$SecurityGroupToJson(SecurityGroup instance) =>
    <String, dynamic>{
      'group_id': instance.groupId,
      'name': instance.name,
      'abbreviation': instance.abbreviation,
      'description': instance.description,
      'date_modified': instance.dateModified,
      'granted_permissions': instance.grantedPermissions,
      'restricted_permissions': instance.restrictedPermissions,
    };
