part 'customer_create_response.g.dart';

class CustomerCreateResponse {
  final bool success;
  final String message;
  final int created;
  final int failed;
  final int addressesCreated;
  final List<int> customerIds;
  final List<CustomerCreateResult> results;
  final List<CustomerCreateFailureDetail> failureDetails;

  CustomerCreateResponse({
    required this.success,
    required this.message,
    required this.created,
    required this.failed,
    required this.addressesCreated,
    required this.customerIds,
    this.results = const [],
    this.failureDetails = const [],
  });

  factory CustomerCreateResponse.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> safeJson = Map<String, dynamic>.from(json);
    safeJson['created'] = json['created'] ?? 0;
    safeJson['failed'] = json['failed'] ?? 0;
    safeJson['addressesCreated'] = json['addressesCreated'] ?? 0;

    final rawIds = json['customerIds'];
    final List<dynamic> safeIds = rawIds is List
        ? rawIds.where((entry) => entry != null).toList()
        : <dynamic>[];
    safeJson['customerIds'] = safeIds;
    final resultsRaw = json['results'];
    final failureRaw = json['failureDetails'];
    final List<CustomerCreateResult> results = resultsRaw is List
        ? resultsRaw
            .whereType<Map>()
            .map(
              (entry) => CustomerCreateResult.fromJson(
                Map<String, dynamic>.from(entry),
              ),
            )
            .toList()
        : const <CustomerCreateResult>[];
    final List<CustomerCreateFailureDetail> failureDetails =
        failureRaw is List
            ? failureRaw
                .whereType<Map>()
                .map(
                  (entry) => CustomerCreateFailureDetail.fromJson(
                    Map<String, dynamic>.from(entry),
                  ),
                )
                .toList()
            : const <CustomerCreateFailureDetail>[];

    return CustomerCreateResponse(
      success: safeJson['success'] as bool? ?? false,
      message: safeJson['message'] as String? ?? '',
      created: safeJson['created'] as int? ?? 0,
      failed: safeJson['failed'] as int? ?? 0,
      addressesCreated: safeJson['addressesCreated'] as int? ?? 0,
      customerIds: safeIds.map((id) => (id as num).toInt()).toList(),
      results: results,
      failureDetails: failureDetails,
    );
  }
}

class CustomerCreateResult {
  final int itemIndex;
  final String? customerIdentifier;
  final bool success;
  final int? customerId;
  final String? failureReason;

  CustomerCreateResult({
    required this.itemIndex,
    required this.customerIdentifier,
    required this.success,
    required this.customerId,
    required this.failureReason,
  });

  factory CustomerCreateResult.fromJson(Map<String, dynamic> json) {
    return CustomerCreateResult(
      itemIndex: (json['itemIndex'] as num?)?.toInt() ?? 0,
      customerIdentifier: json['customerIdentifier'] as String?,
      success: json['success'] as bool? ?? false,
      customerId: (json['customerId'] as num?)?.toInt(),
      failureReason: json['failureReason'] as String?,
    );
  }
}

class CustomerCreateFailureDetail {
  final int itemIndex;
  final String? customerIdentifier;
  final String? reason;

  CustomerCreateFailureDetail({
    required this.itemIndex,
    required this.customerIdentifier,
    required this.reason,
  });

  factory CustomerCreateFailureDetail.fromJson(Map<String, dynamic> json) {
    return CustomerCreateFailureDetail(
      itemIndex: (json['itemIndex'] as num?)?.toInt() ?? 0,
      customerIdentifier: json['customerIdentifier'] as String?,
      reason: json['reason'] as String?,
    );
  }
}
