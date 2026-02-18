import 'package:rmstock_scanner/features/stock_lookup/domain/entities/sync_status.dart';
import 'package:rmstock_scanner/features/stock_lookup/domain/repositories/stock_lookup_repo.dart';

import '../../../../local_db/local_db_dao.dart';
import '../../../../utils/internet_connection_utils.dart';
class FetchStockData {
  final StockLookupRepo repository;

  FetchStockData(this.repository);

  Stream<SyncStatus> call(String ip, String? userName, String? pwd) async* {
    try {
      if (await InternetConnectionUtils.instance.checkInternetConnection()) {
        final String savedIp =
            (await LocalDbDAO.instance.getHostIpAddress() ?? "").trim();
        final String targetIp = savedIp.isNotEmpty ? savedIp : ip.trim();

        // Old setup disabled:
        // - path-based shared-folder polling
        // - SMB credential persistence for stock lookup sync
        yield* repository.fetchAndSaveStocks(targetIp);
      } else {
        yield* Stream.error("Please connect to a network!");
      }
    } catch (error) {
      yield* Stream.error(error);
    }
  }
}
