import 'package:json_annotation/json_annotation.dart';

part 'staff_detail_response.g.dart';

@JsonSerializable()
class StaffDetailResponse {
  final bool success;
  final String message;
  final String shopfrontId;
  final String shopfrontName;
  @JsonKey(name: 'security_enabled')
  final bool securityEnabled;
  final StaffDetailInfo? staff;

  StaffDetailResponse({
    required this.success,
    required this.message,
    required this.shopfrontId,
    required this.shopfrontName,
    required this.securityEnabled,
    this.staff,
  });

  factory StaffDetailResponse.fromJson(Map<String, dynamic> json) =>
      _$StaffDetailResponseFromJson(json);
}

@JsonSerializable()
class StaffDetailInfo {
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

  StaffDetailInfo({
    required this.staffId,
    required this.staffNo,
    required this.givenNames,
    required this.surname,
    this.docketName,
    required this.groupIds,
    required this.isAssigned,
    required this.hasPassword,
  });

  factory StaffDetailInfo.fromJson(Map<String, dynamic> json) =>
      _$StaffDetailInfoFromJson(json);
}
