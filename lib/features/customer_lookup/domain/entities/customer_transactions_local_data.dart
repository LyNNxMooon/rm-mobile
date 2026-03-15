class CustomerTransactionsLocalData {
  final List<Map<String, dynamic>> purchases;
  final List<Map<String, dynamic>> credit;
  final List<Map<String, dynamic>> invoices;
  final List<Map<String, dynamic>> ivPay;
  final List<Map<String, dynamic>> laybys;
  final List<Map<String, dynamic>> lbPay;
  final List<Map<String, dynamic>> cso;
  final List<Map<String, dynamic>> soQuote;
  final List<Map<String, dynamic>> soPay;

  CustomerTransactionsLocalData({
    required this.purchases,
    required this.credit,
    required this.invoices,
    required this.ivPay,
    required this.laybys,
    required this.lbPay,
    required this.cso,
    required this.soQuote,
    required this.soPay,
  });

  factory CustomerTransactionsLocalData.empty() {
    return CustomerTransactionsLocalData(
      purchases: const [],
      credit: const [],
      invoices: const [],
      ivPay: const [],
      laybys: const [],
      lbPay: const [],
      cso: const [],
      soQuote: const [],
      soPay: const [],
    );
  }
}
