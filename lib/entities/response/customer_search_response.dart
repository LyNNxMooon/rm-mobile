import '../vos/customer_vo.dart';

class CustomerSearchResult {
  final CustomerVO? customer;
  final List<CustomerVO> duplicates;
  final bool notFound;

  const CustomerSearchResult({
    required this.customer,
    required this.duplicates,
    required this.notFound,
  });

  factory CustomerSearchResult.found(CustomerVO c) =>
      CustomerSearchResult(customer: c, duplicates: const [], notFound: false);

  factory CustomerSearchResult.duplicates(List<CustomerVO> list) =>
      CustomerSearchResult(customer: null, duplicates: list, notFound: false);

  factory CustomerSearchResult.none() =>
      const CustomerSearchResult(customer: null, duplicates: [], notFound: true);
}
