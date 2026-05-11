/// Pagination info for a transaction type
class TransactionPaginationInfo {
  final bool hasMore;
  final int? nextCursor;

  const TransactionPaginationInfo({
    this.hasMore = false,
    this.nextCursor,
  });

  static const empty = TransactionPaginationInfo();
}

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
  
  // Pagination info per transaction type
  final Map<String, TransactionPaginationInfo> _pagination;
  
  Map<String, TransactionPaginationInfo> get pagination => _pagination;

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
    Map<String, TransactionPaginationInfo>? pagination,
  }) : _pagination = pagination ?? const {};

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
      pagination: const {},
    );
  }

  /// Copy with updated pagination info for a specific type
  CustomerTransactionsLocalData copyWithPagination(
    String transactionType,
    TransactionPaginationInfo info,
  ) {
    final newPagination = Map<String, TransactionPaginationInfo>.from(_pagination);
    newPagination[transactionType] = info;
    return CustomerTransactionsLocalData(
      purchases: purchases,
      credit: credit,
      invoices: invoices,
      ivPay: ivPay,
      laybys: laybys,
      lbPay: lbPay,
      cso: cso,
      soQuote: soQuote,
      soPay: soPay,
      pagination: newPagination,
    );
  }

  /// Get pagination info for a transaction type
  TransactionPaginationInfo getPagination(String transactionType) {
    return _pagination[transactionType] ?? TransactionPaginationInfo.empty;
  }
}
