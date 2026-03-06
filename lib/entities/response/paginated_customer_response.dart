import '../vos/customer_vo.dart';

class PaginatedCustomerResult {
  final List<CustomerVO> customers;
  final int totalCount;
  final bool hasMore;

  PaginatedCustomerResult({
    required this.customers,
    required this.totalCount,
    required this.hasMore,
  });
}
