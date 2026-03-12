import '../vos/customer_vo.dart';

class PaginatedCustomerResult {
  final List<CustomerVO> customers;
  final int totalCount;
  final bool hasMore;
  final Map<int, String> matchedFields; // customerId -> matched column name

  PaginatedCustomerResult({
    required this.customers,
    required this.totalCount,
    required this.hasMore,
    Map<int, String>? matchedFields,
  }) : matchedFields = matchedFields ?? {};
}
