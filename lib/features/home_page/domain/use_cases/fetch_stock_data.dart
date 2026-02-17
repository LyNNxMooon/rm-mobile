import 'package:rmstock_scanner/features/home_page/domain/repositories/home_repo.dart';

import '../../../../local_db/local_db_dao.dart';
import '../../../../utils/internet_connection_utils.dart';
import '../../models/home_screen_models.dart';

class FetchStockData {
  final HomeRepo repository;

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
        yield* repository.fetchAndSaveStocks(
          targetIp,
          "",
          null,
          null,
          "",
          "",
        );
      } else {
        yield* Stream.error("Please connect to a network!");
      }
    } catch (error) {
      yield* Stream.error(error);
    }
  }
}
