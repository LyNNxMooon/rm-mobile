abstract class CustomerCreateEvent {}

class CreateCustomerEvent extends CustomerCreateEvent {
  final Map<String, dynamic> customerData;

  CreateCustomerEvent(this.customerData);
}

class ValidateBarcodeEvent extends CustomerCreateEvent {
  final String barcode;

  ValidateBarcodeEvent(this.barcode);
}

class GenerateBarcodeEvent extends CustomerCreateEvent {}

class ResetCustomerCreateEvent extends CustomerCreateEvent {}
