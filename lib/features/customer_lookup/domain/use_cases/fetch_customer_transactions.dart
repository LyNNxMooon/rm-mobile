import '../../../../local_db/local_db_dao.dart';
import '../../../../utils/internet_connection_utils.dart';
import '../repositories/customer_lookup_repo.dart';

class FetchCustomerTransactions {
  final CustomerLookupRepo repository;

  FetchCustomerTransactions(this.repository);

  Future<void> call(int customerId) async {
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

    return repository.fetchAndSaveCustomerTransactions(customerId: customerId);
  }
}
