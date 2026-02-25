// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: unused_element

part of 'authenticate_staff_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AuthenticateStaffResponse _$AuthenticateStaffResponseFromJson(
  Map<String, dynamic> json,
) => AuthenticateStaffResponse(
  success: json['success'] as bool,
  message: json['message'] as String,
  securityEnabled: json['security_enabled'] as bool,
  staff: json['staff'] == null
      ? null
      : StaffInfo.fromJson(json['staff'] as Map<String, dynamic>),
  groupIds:
      (json['group_ids'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList() ??
      const <int>[],
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

Map<String, dynamic> _$AuthenticateStaffResponseToJson(
  AuthenticateStaffResponse instance,
) => <String, dynamic>{
  'success': instance.success,
  'message': instance.message,
  'security_enabled': instance.securityEnabled,
  'staff': instance.staff,
  'group_ids': instance.groupIds,
  'granted_permissions': instance.grantedPermissions,
  'restricted_permissions': instance.restrictedPermissions,
};

StaffInfo _$StaffInfoFromJson(Map<String, dynamic> json) => StaffInfo(
  staffId: (json['staff_id'] as num).toInt(),
  staffNo: json['staff_no'] as String,
  givenNames: json['given_names'] as String,
  surname: json['surname'] as String,
  docketName: json['docket_name'] as String?,
  groupIds:
      (json['group_ids'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList() ??
      const <int>[],
  isAssigned: json['is_assigned'] as bool,
  hasPassword: json['has_password'] as bool,
);

Map<String, dynamic> _$StaffInfoToJson(StaffInfo instance) => <String, dynamic>{
  'staff_id': instance.staffId,
  'staff_no': instance.staffNo,
  'given_names': instance.givenNames,
  'surname': instance.surname,
  'docket_name': instance.docketName,
  'group_ids': instance.groupIds,
  'is_assigned': instance.isAssigned,
  'has_password': instance.hasPassword,
};

StaffPermission _$StaffPermissionFromJson(Map<String, dynamic> json) =>
    StaffPermission(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
    );

Map<String, dynamic> _$StaffPermissionToJson(StaffPermission instance) =>
    <String, dynamic>{'id': instance.id, 'name': instance.name};
