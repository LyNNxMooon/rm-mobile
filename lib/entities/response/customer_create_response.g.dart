part of 'customer_create_response.dart';

CustomerCreateResponse _$CustomerCreateResponseFromJson(
  Map<String, dynamic> json,
) =>
    CustomerCreateResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      created: (json['created'] as num?)?.toInt() ?? 0,
      failed: (json['failed'] as num?)?.toInt() ?? 0,
      addressesCreated: (json['addressesCreated'] as num?)?.toInt() ?? 0,
      customerIds: (json['customerIds'] as List<dynamic>?)
              ?.where((entry) => entry != null)
              .map((entry) => (entry as num).toInt())
              .toList() ??
          <int>[],
      results: (json['results'] as List<dynamic>?)
              ?.whereType<Map>()
              .map(
                (entry) => CustomerCreateResult.fromJson(
                  Map<String, dynamic>.from(entry),
                ),
              )
              .toList() ??
          const <CustomerCreateResult>[],
      failureDetails: (json['failureDetails'] as List<dynamic>?)
              ?.whereType<Map>()
              .map(
                (entry) => CustomerCreateFailureDetail.fromJson(
                  Map<String, dynamic>.from(entry),
                ),
              )
              .toList() ??
          const <CustomerCreateFailureDetail>[],
    );

Map<String, dynamic> _$CustomerCreateResponseToJson(
  CustomerCreateResponse instance,
) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'created': instance.created,
      'failed': instance.failed,
      'addressesCreated': instance.addressesCreated,
      'customerIds': instance.customerIds,
      'results': instance.results.map(_$CustomerCreateResultToJson).toList(),
      'failureDetails': instance.failureDetails
          .map(_$CustomerCreateFailureDetailToJson)
          .toList(),
    };

Map<String, dynamic> _$CustomerCreateResultToJson(
  CustomerCreateResult instance,
) =>
    <String, dynamic>{
      'itemIndex': instance.itemIndex,
      'customerIdentifier': instance.customerIdentifier,
      'success': instance.success,
      'customerId': instance.customerId,
      'failureReason': instance.failureReason,
    };

Map<String, dynamic> _$CustomerCreateFailureDetailToJson(
  CustomerCreateFailureDetail instance,
) =>
    <String, dynamic>{
      'itemIndex': instance.itemIndex,
      'customerIdentifier': instance.customerIdentifier,
      'reason': instance.reason,
    };
