abstract class CustomerCreateEvent {}

class CustomerCreateAddressInput {
  final int addressNumber;
  final String addr1;
  final String addr2;
  final String addr3;
  final String suburb;
  final String state;
  final String postcode;
  final String country;
  final String phone;
  final String mobile;
  final String email;

  CustomerCreateAddressInput({
    required this.addressNumber,
    required this.addr1,
    required this.addr2,
    required this.addr3,
    required this.suburb,
    required this.state,
    required this.postcode,
    required this.country,
    required this.phone,
    required this.mobile,
    required this.email,
  });
}

class CustomerCreateFormInput {
  final String barcode;
  final String surname;
  final String givenNames;
  final int grade;
  final String company;
  final String position;
  final String salutation;
  final bool status;
  final bool inactive;
  final bool account;
  final bool overseas;
  final bool fromEom;
  final String abn;
  final String notes;
  final String comments;
  final String custom1;
  final String custom2;
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
  final int? openedStaffId;
  final int? ownerStaffId;
  final int days;
  final double limit;
  final int defaultDeliveryAddress;
  final int documentDeliveryType;
  final List<CustomerCreateAddressInput> secondaryAddresses;

  CustomerCreateFormInput({
    required this.barcode,
    required this.surname,
    required this.givenNames,
    required this.grade,
    required this.company,
    required this.position,
    required this.salutation,
    required this.status,
    required this.inactive,
    required this.account,
    required this.overseas,
    required this.fromEom,
    required this.abn,
    required this.notes,
    required this.comments,
    required this.custom1,
    required this.custom2,
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
    required this.openedStaffId,
    required this.ownerStaffId,
    required this.days,
    required this.limit,
    required this.defaultDeliveryAddress,
    required this.documentDeliveryType,
    required this.secondaryAddresses,
  });
}

class CreateCustomerEvent extends CustomerCreateEvent {
  final Map<String, dynamic> customerData;

  CreateCustomerEvent(this.customerData);
}

class SubmitCustomerCreateFormEvent extends CustomerCreateEvent {
  final CustomerCreateFormInput form;

  SubmitCustomerCreateFormEvent(this.form);
}

class ValidateBarcodeEvent extends CustomerCreateEvent {
  final String barcode;

  ValidateBarcodeEvent(this.barcode);
}

class GenerateBarcodeEvent extends CustomerCreateEvent {}

class ResetCustomerCreateEvent extends CustomerCreateEvent {}
