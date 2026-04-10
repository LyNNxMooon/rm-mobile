/// Response for account invoice creation
class InvoiceResponse {
  final bool success;
  final String message;
  final int? invoiceId;
  final String? invoiceNumber;

  InvoiceResponse({
    required this.success,
    required this.message,
    this.invoiceId,
    this.invoiceNumber,
  });

  factory InvoiceResponse.fromJson(Map<String, dynamic> json) {
    final bool hasInvoiceId = json['invoiceId'] != null;
    final bool hasInvoiceNumber = json['invoiceNumber'] != null;
    return InvoiceResponse(
      success: json['success'] as bool? ?? (hasInvoiceId || hasInvoiceNumber),
      message: json['message'] as String? ?? '',
      invoiceId: (json['invoiceId'] as num?)?.toInt(),
      invoiceNumber: json['invoiceNumber'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      if (invoiceId != null) 'invoiceId': invoiceId,
      if (invoiceNumber != null) 'invoiceNumber': invoiceNumber,
    };
  }
}
