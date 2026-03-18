class PendingCustomerUpdateVO {
  final int id;
  final String shopfront;
  final int customerId;
  final String action;
  final Map<String, dynamic> payload;
  final String createdAt;
  final bool hasConflict;
  final String? errorMessage;

  PendingCustomerUpdateVO({
    required this.id,
    required this.shopfront,
    required this.customerId,
    required this.action,
    required this.payload,
    required this.createdAt,
    required this.hasConflict,
    this.errorMessage,
  });
}