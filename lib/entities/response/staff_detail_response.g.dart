// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'staff_detail_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StaffDetailResponse _$StaffDetailResponseFromJson(Map<String, dynamic> json) =>
    StaffDetailResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
      shopfrontId: json['shopfrontId'] as String,
      shopfrontName: json['shopfrontName'] as String,
      securityEnabled: json['security_enabled'] as bool,
      staff: json['staff'] == null
          ? null
          : StaffDetailInfo.fromJson(json['staff'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$StaffDetailResponseToJson(StaffDetailResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'shopfrontId': instance.shopfrontId,
      'shopfrontName': instance.shopfrontName,
      'security_enabled': instance.securityEnabled,
      'staff': instance.staff,
    };

StaffDetailInfo _$StaffDetailInfoFromJson(Map<String, dynamic> json) =>
    StaffDetailInfo(
      staffId: (json['staff_id'] as num).toInt(),
      staffNo: json['staff_no'] as String,
      givenNames: json['given_names'] as String,
      surname: json['surname'] as String,
      docketName: json['docket_name'] as String?,
      groupIds: (json['group_ids'] as List<dynamic>)
          .map((e) => (e as num).toInt())
          .toList(),
      isAssigned: json['is_assigned'] as bool,
      hasPassword: json['has_password'] as bool,
    );

Map<String, dynamic> _$StaffDetailInfoToJson(StaffDetailInfo instance) =>
    <String, dynamic>{
      'staff_id': instance.staffId,
      'staff_no': instance.staffNo,
      'given_names': instance.givenNames,
      'surname': instance.surname,
      'docket_name': instance.docketName,
      'group_ids': instance.groupIds,
      'is_assigned': instance.isAssigned,
      'has_password': instance.hasPassword,
    };
