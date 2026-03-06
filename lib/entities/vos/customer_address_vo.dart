import 'package:json_annotation/json_annotation.dart';
part 'customer_address_vo.g.dart';

@JsonSerializable()
class CustomerAddressVO {
  @JsonKey(name: 'addressId')
  final int addressId;
  @JsonKey(name: 'customerId')
  final int customerId;
  @JsonKey(name: 'addressNumber')
  final int addressNumber;
  final String addr1;
  final String addr2;
  final String addr3;
  final String suburb;
  final String state;
  final String postcode;
  final String country;
  final String phone;
  final String fax;
  final String mobile;
  final String email;

  CustomerAddressVO({
    required this.addressId,
    required this.customerId,
    required this.addressNumber,
    required this.addr1,
    required this.addr2,
    required this.addr3,
    required this.suburb,
    required this.state,
    required this.postcode,
    required this.country,
    required this.phone,
    required this.fax,
    required this.mobile,
    required this.email,
  });

  factory CustomerAddressVO.fromJson(Map<String, dynamic> json) =>
      _$CustomerAddressVOFromJson(json);

  Map<String, dynamic> toJson() => _$CustomerAddressVOToJson(this);

  factory CustomerAddressVO.fromApiItem(Map<String, dynamic> item) {
    return CustomerAddressVO(
      addressId: item["addressId"] ?? 0,
      customerId: item["customerId"] ?? 0,
      addressNumber: item["addressNumber"] ?? 0,
      addr1: item["addr1"] ?? "",
      addr2: item["addr2"] ?? "",
      addr3: item["addr3"] ?? "",
      suburb: item["suburb"] ?? "",
      state: item["state"] ?? "",
      postcode: item["postcode"] ?? "",
      country: item["country"] ?? "",
      phone: item["phone"] ?? "",
      fax: item["fax"] ?? "",
      mobile: item["mobile"] ?? "",
      email: item["email"] ?? "",
    );
  }
}
