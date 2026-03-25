/// Model to hold delivery information for a sale
class DeliveryInfo {
  final int? customerId;
  final String recipientName;
  final String phone;
  final String mobile;
  final String email;
  final String addr1;
  final String addr2;
  final String addr3;
  final String suburb;
  final String state;
  final String postcode;
  final String country;
  final String deliveryMethod;
  final DateTime? deliveryDate;
  final String notes;
  final String addressSource; // "primary", "address_2", "address_3", "other"

  const DeliveryInfo({
    this.customerId,
    this.recipientName = '',
    this.phone = '',
    this.mobile = '',
    this.email = '',
    this.addr1 = '',
    this.addr2 = '',
    this.addr3 = '',
    this.suburb = '',
    this.state = '',
    this.postcode = '',
    this.country = '',
    this.deliveryMethod = 'Standard',
    this.deliveryDate,
    this.notes = '',
    this.addressSource = 'primary',
  });

  DeliveryInfo copyWith({
    int? customerId,
    String? recipientName,
    String? phone,
    String? mobile,
    String? email,
    String? addr1,
    String? addr2,
    String? addr3,
    String? suburb,
    String? state,
    String? postcode,
    String? country,
    String? deliveryMethod,
    DateTime? deliveryDate,
    String? notes,
    String? addressSource,
  }) {
    return DeliveryInfo(
      customerId: customerId ?? this.customerId,
      recipientName: recipientName ?? this.recipientName,
      phone: phone ?? this.phone,
      mobile: mobile ?? this.mobile,
      email: email ?? this.email,
      addr1: addr1 ?? this.addr1,
      addr2: addr2 ?? this.addr2,
      addr3: addr3 ?? this.addr3,
      suburb: suburb ?? this.suburb,
      state: state ?? this.state,
      postcode: postcode ?? this.postcode,
      country: country ?? this.country,
      deliveryMethod: deliveryMethod ?? this.deliveryMethod,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      notes: notes ?? this.notes,
      addressSource: addressSource ?? this.addressSource,
    );
  }

  /// Get full address as single line
  String get fullAddress {
    final parts = <String>[];
    if (addr1.isNotEmpty) parts.add(addr1);
    if (addr2.isNotEmpty) parts.add(addr2);
    if (addr3.isNotEmpty) parts.add(addr3);
    if (suburb.isNotEmpty) parts.add(suburb);
    if (state.isNotEmpty) parts.add(state);
    if (postcode.isNotEmpty) parts.add(postcode);
    if (country.isNotEmpty) parts.add(country);
    return parts.join(', ');
  }

  /// Check if delivery info has been filled
  bool get isValid => recipientName.isNotEmpty && addr1.isNotEmpty;
}
