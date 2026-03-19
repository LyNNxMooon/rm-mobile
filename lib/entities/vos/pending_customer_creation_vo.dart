class PendingCustomerCreationVO {
  final int id;
  final String shopfront;
  final int customerId;
  final Map<String, dynamic> payload;
  final String createdAt;
  final String? errorMessage;

  PendingCustomerCreationVO({
    required this.id,
    required this.shopfront,
    required this.customerId,
    required this.payload,
    required this.createdAt,
    this.errorMessage,
  });
}
