import 'package:json_annotation/json_annotation.dart';

part 'customer_balance_response.g.dart';

@JsonSerializable()
class CustomerBalanceResponse {
  final bool success;
  final String? message;
  @JsonKey(name: 'shopfrontId')
  final String? shopfrontId;
  @JsonKey(name: 'customerId')
  final int customerId;
  @JsonKey(name: 'owingAmount')
  final num owingAmount;
  @JsonKey(name: 'creditLimit')
  final num creditLimit;
  @JsonKey(name: 'remainingCredit')
  final num remainingCredit;

  CustomerBalanceResponse({
    required this.success,
    required this.message,
    required this.shopfrontId,
    required this.customerId,
    required this.owingAmount,
    required this.creditLimit,
    required this.remainingCredit,
  });

  factory CustomerBalanceResponse.fromJson(Map<String, dynamic> json) =>
      _$CustomerBalanceResponseFromJson(json);
}
