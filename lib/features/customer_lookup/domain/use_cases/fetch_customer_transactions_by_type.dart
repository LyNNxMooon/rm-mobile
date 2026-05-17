import '../../../../local_db/local_db_dao.dart';
import '../../../../utils/internet_connection_utils.dart';
import '../repositories/customer_lookup_repo.dart';

class FetchCustomerTransactionsByType {
  final CustomerLookupRepo repository;

  FetchCustomerTransactionsByType(this.repository);

  /// Fetches and saves a single transaction type for a customer
  /// [transactionType] must be one of: purchase, invoice, credit, ivpay, layby, lbpay, cso, soquote, sopay
  /// [pageSize] controls how many records to fetch (default 500)
  /// [cursor] is the pagination cursor for fetching next page
  /// Returns pagination info (hasMore, nextCursor)
  Future<({bool hasMore, int? nextCursor})> call(
    int customerId, {
    required String transactionType,
    int pageSize = 500,
    int? cursor,
  }) async {
    if (!await InternetConnectionUtils.instance.checkInternetConnection()) {
      return Future.error("Please connect to a network!");
    }

    final String shopfront =
        (await LocalDbDAO.instance.getShopfrontName() ?? "").trim();
    if (shopfront.isEmpty) {
      return Future.error(
        "Missing shopfront setup. Please reconnect to a host and shopfront.",
      );
    }

    return repository.fetchAndSaveCustomerTransactionsByType(
      customerId: customerId,
      transactionType: transactionType,
      pageSize: pageSize,
      cursor: cursor,
    );
  }
}
