// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'customer_address_vo.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CustomerAddressVO _$CustomerAddressVOFromJson(Map<String, dynamic> json) =>
    CustomerAddressVO(
      addressId: (json['addressId'] as num).toInt(),
      customerId: (json['customerId'] as num).toInt(),
      addressNumber: (json['addressNumber'] as num).toInt(),
      addr1: json['addr1'] as String,
      addr2: json['addr2'] as String,
      addr3: json['addr3'] as String,
      suburb: json['suburb'] as String,
      state: json['state'] as String,
      postcode: json['postcode'] as String,
      country: json['country'] as String,
      phone: json['phone'] as String,
      fax: json['fax'] as String,
      mobile: json['mobile'] as String,
      email: json['email'] as String,
    );

Map<String, dynamic> _$CustomerAddressVOToJson(CustomerAddressVO instance) =>
    <String, dynamic>{
      'addressId': instance.addressId,
      'customerId': instance.customerId,
      'addressNumber': instance.addressNumber,
      'addr1': instance.addr1,
      'addr2': instance.addr2,
      'addr3': instance.addr3,
      'suburb': instance.suburb,
      'state': instance.state,
      'postcode': instance.postcode,
      'country': instance.country,
      'phone': instance.phone,
      'fax': instance.fax,
      'mobile': instance.mobile,
      'email': instance.email,
    };
