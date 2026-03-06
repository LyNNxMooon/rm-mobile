import 'package:rmstock_scanner/features/customer_lookup/domain/entities/customer_sync_status.dart';
import 'package:rmstock_scanner/features/customer_lookup/domain/repositories/customer_lookup_repo.dart';

import '../../../../local_db/local_db_dao.dart';
import '../../../../utils/internet_connection_utils.dart';

class FetchCustomerData {
  final CustomerLookupRepo repository;

  FetchCustomerData(this.repository);

  Stream<CustomerSyncStatus> call(String ip, String? userName, String? pwd) async* {
    try {
      if (await InternetConnectionUtils.instance.checkInternetConnection()) {
        final String savedIp =
            (await LocalDbDAO.instance.getHostIpAddress() ?? "").trim();
        final String targetIp = savedIp.isNotEmpty ? savedIp : ip.trim();

        yield* repository.fetchAndSaveCustomers(targetIp);
      } else {
        yield* Stream.error("Please connect to a network!");
      }
    } catch (error) {
      yield* Stream.error(error);
    }
  }
}
