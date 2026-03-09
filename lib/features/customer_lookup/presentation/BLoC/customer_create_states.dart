abstract class CustomerCreateState {}

class CustomerCreateInitial extends CustomerCreateState {}

class CustomerCreateLoading extends CustomerCreateState {}

class CustomerCreateSuccess extends CustomerCreateState {
  final String message;
  final List<int> customerIds;

  CustomerCreateSuccess({
    required this.message,
    required this.customerIds,
  });
}

class CustomerCreateError extends CustomerCreateState {
  final String error;

  CustomerCreateError(this.error);
}

class BarcodeValidationState extends CustomerCreateState {
  final bool isValid;
  final String? message;
  final String barcode;

  BarcodeValidationState({
    required this.isValid,
    this.message,
    required this.barcode,
  });
}

class BarcodeGeneratedState extends CustomerCreateState {
  final String barcode;

  BarcodeGeneratedState(this.barcode);
}
