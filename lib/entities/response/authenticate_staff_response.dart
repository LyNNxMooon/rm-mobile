import 'package:json_annotation/json_annotation.dart';

part 'authenticate_staff_response.g.dart';

@JsonSerializable()
class AuthenticateStaffResponse {
  final bool success;
  final String message;
  @JsonKey(name: 'security_enabled')
  final bool securityEnabled;
  final StaffInfo? staff;
  @JsonKey(name: 'group_ids')
  final List<int> groupIds;
  @JsonKey(name: 'granted_permissions')
  final List<StaffPermission> grantedPermissions;
  @JsonKey(name: 'restricted_permissions')
  final List<StaffPermission> restrictedPermissions;

  AuthenticateStaffResponse({
    required this.success,
    required this.message,
    required this.securityEnabled,
    this.staff,
    required this.groupIds,
    required this.grantedPermissions,
    required this.restrictedPermissions,
  });

  factory AuthenticateStaffResponse.fromJson(Map<String, dynamic> json) =>
      _$AuthenticateStaffResponseFromJson(json);
}

@JsonSerializable()
class StaffInfo {
  @JsonKey(name: 'staff_id')
  final int staffId;
  @JsonKey(name: 'staff_no')
  final String staffNo;
  @JsonKey(name: 'given_names')
  final String givenNames;
  final String surname;
  @JsonKey(name: 'docket_name')
  final String? docketName;
  @JsonKey(name: 'group_ids')
  final List<int> groupIds;
  @JsonKey(name: 'is_assigned')
  final bool isAssigned;
  @JsonKey(name: 'has_password')
  final bool hasPassword;

  StaffInfo({
    required this.staffId,
    required this.staffNo,
    required this.givenNames,
    required this.surname,
    this.docketName,
    required this.groupIds,
    required this.isAssigned,
    required this.hasPassword,
  });

  factory StaffInfo.fromJson(Map<String, dynamic> json) =>
      _$StaffInfoFromJson(json);
}

@JsonSerializable()
class StaffPermission {
  final int id;
  final String name;

  StaffPermission({required this.id, required this.name});

  factory StaffPermission.fromJson(Map<String, dynamic> json) =>
      _$StaffPermissionFromJson(json);
}
