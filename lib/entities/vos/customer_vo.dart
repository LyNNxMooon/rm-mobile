import 'package:json_annotation/json_annotation.dart';
import 'package:rmstock_scanner/entities/vos/customer_address_vo.dart';
part 'customer_vo.g.dart';

@JsonSerializable()
class CustomerVO {
  @JsonKey(name: 'customer_id')
  final int customerId;
  final String barcode;
  final int grade;
  final String notes;
  final String comments;
  final bool status;
  final String custom1;
  final String custom2;
  final bool inactive;
  @JsonKey(name: 'date_modified')
  final String dateModified;
  final String surname;
  @JsonKey(name: 'given_names')
  final String givenNames;
  final String position;
  final String company;
  final String salutation;
  final bool account;
  @JsonKey(name: 'opened_id')
  final int openedId;
  @JsonKey(name: 'owner_id')
  final int ownerId;
  final num limit;
  final int days;
  @JsonKey(name: 'from_eom')
  final bool fromEOM;
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
  final String abn;
  final bool overseas;
  final bool external;
  @JsonKey(name: 'date_created')
  final String dateCreated;
  @JsonKey(name: 'is_barcode_printed')
  final bool isBarcodePrinted;
  @JsonKey(name: 'document_delivery_type')
  final int documentDeliveryType;
  @JsonKey(name: 'group_email_exclusion_id')
  final int groupEmailExclusionId;
  @JsonKey(name: 'default_delivery_address')
  final int defaultDeliveryAddress;
  final List<CustomerAddressVO> addresses;

  CustomerVO({
    required this.customerId,
    required this.barcode,
    required this.grade,
    required this.notes,
    required this.comments,
    required this.status,
    required this.custom1,
    required this.custom2,
    required this.inactive,
    required this.dateModified,
    required this.surname,
    required this.givenNames,
    required this.position,
    required this.company,
    required this.salutation,
    required this.account,
    required this.openedId,
    required this.ownerId,
    required this.limit,
    required this.days,
    required this.fromEOM,
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
    required this.abn,
    required this.overseas,
    required this.external,
    required this.dateCreated,
    required this.isBarcodePrinted,
    required this.documentDeliveryType,
    required this.groupEmailExclusionId,
    required this.defaultDeliveryAddress,
    required this.addresses,
  });

  factory CustomerVO.fromJson(Map<String, dynamic> json) =>
      _$CustomerVOFromJson(json);

  factory CustomerVO.fromJsonNetwork(Map<String, dynamic> json) =>
      _$CustomerVOFromJsonNetwork(json);

  Map<String, dynamic> toJson(String currentShopfront) =>
      _$CustomerVOToJson(this, currentShopfront);

  factory CustomerVO.fromApiItem(Map<String, dynamic> item) {
    final addressesList = item["addresses"] as List<dynamic>? ?? [];
    final addresses = addressesList
        .map((addr) {
          if (addr is CustomerAddressVO) return addr;
          if (addr is Map<String, dynamic>) {
            return CustomerAddressVO.fromApiItem(addr);
          }
          if (addr is Map) {
            return CustomerAddressVO.fromApiItem(
              Map<String, dynamic>.from(addr),
            );
          }
          return CustomerAddressVO.fromApiItem(const {});
        })
        .toList();

    return CustomerVO(
      customerId:
          _asNum(item["customer_id"] ?? item["customerId"]).toInt(),
      barcode: _asString(item["barcode"]),
      grade: _asNum(item["grade"]).toInt(),
      notes: _asString(item["notes"]),
      comments: _asString(item["comments"]),
      status: _asBool(item["status"]),
      custom1: _asString(item["custom1"]),
      custom2: _asString(item["custom2"]),
      inactive: _asBool(item["inactive"]),
      dateModified:
          _asString(item["date_modified"] ?? item["dateModified"]),
      surname: _asString(item["surname"]),
      givenNames: _asString(item["given_names"] ?? item["givenNames"]),
      position: _asString(item["position"]),
      company: _asString(item["company"]),
      salutation: _asString(item["salutation"]),
      account: _asBool(item["account"]),
      openedId: _asNum(item["opened_id"] ?? item["openedId"]).toInt(),
      ownerId: _asNum(item["owner_id"] ?? item["ownerId"]).toInt(),
      limit: _asNum(item["limit"]),
      days: _asNum(item["days"]).toInt(),
      fromEOM: _asBool(item["from_eom"] ?? item["fromEOM"]),
      addr1: _asString(item["addr1"]),
      addr2: _asString(item["addr2"]),
      addr3: _asString(item["addr3"]),
      suburb: _asString(item["suburb"]),
      state: _asString(item["state"]),
      postcode: _asString(item["postcode"]),
      country: _asString(item["country"]),
      phone: _asString(item["phone"]),
      fax: _asString(item["fax"]),
      mobile: _asString(item["mobile"]),
      email: _asString(item["email"]),
      abn: _asString(item["abn"]),
      overseas: _asBool(item["overseas"]),
      external: _asBool(item["external"]),
      dateCreated: _asString(item["date_created"] ?? item["dateCreated"]),
      isBarcodePrinted: _asBool(
        item["is_barcode_printed"] ?? item["isBarcodePrinted"],
      ),
      documentDeliveryType: _asNum(
        item["document_delivery_type"] ?? item["documentDeliveryType"],
      ).toInt(),
      groupEmailExclusionId: _asNum(
        item["group_email_exclusion_id"] ?? item["groupEmailExclusionId"],
      ).toInt(),
      defaultDeliveryAddress: _asNum(
        item["default_delivery_address"] ??
            item["defaultDeliveryAddress"] ??
            1,
      ).toInt(),
      addresses: addresses,
    );
  }

  String get displayName {
    final name = givenNames.isNotEmpty 
        ? "$givenNames $surname".trim() 
        : surname;
    return company.isNotEmpty ? "$name ($company)" : name;
  }

  String get fullAddress {
    final parts = [addr1, addr2, addr3, suburb, state, postcode, country]
        .where((s) => s.isNotEmpty)
        .toList();
    return parts.join(", ");
  }

  static String _asString(dynamic value) {
    return value == null ? "" : value.toString();
  }

  static String? _asNullableString(dynamic value) {
    if (value == null) return null;
    final parsed = value.toString();
    return parsed.isEmpty ? null : parsed;
  }

  static int? _asInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static num _asNum(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value;
    final parsed = num.tryParse(value.toString());
    return parsed ?? 0;
  }

  static bool _asBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final lower = value.toLowerCase();
      return lower == "true" || lower == "1";
    }
    return false;
  }
}
