import 'package:rmstock_scanner/features/home_page/domain/repositories/home_repo.dart';

import '../../../../entities/vos/device_metedata_vo.dart';
import '../../../../local_db/local_db_dao.dart';
import '../../../../utils/device_meta_data_utils.dart';
import '../../../../utils/global_var_utils.dart';
import '../../../../utils/internet_connection_utils.dart';
import '../../models/home_screen_models.dart';

class FetchStockData {
  final HomeRepo repository;

  FetchStockData(this.repository);

  Stream<SyncStatus> call(String ip, String? userName, String? pwd) async* {
    try {
      if (await InternetConnectionUtils.instance.checkInternetConnection()) {
        final DeviceMetadata mobileInfo = await DeviceMetaDataUtils.instance
            .getDeviceInformation();

        if (userName != null && pwd != null) {
          LocalDbDAO.instance.removeNetworkCredential(ip: ip);

          if ((userName).isNotEmpty && (pwd).isNotEmpty) {
            LocalDbDAO.instance.saveNetworkCredential(
              ip: ip,
              username: userName,
              password: pwd,
            );
          }

          yield* repository.fetchAndSaveStocks(
            ip,
            AppGlobals.instance.currentPath ?? "",
            userName,
            pwd,
            mobileInfo.deviceId,
            AppGlobals.instance.shopfront ?? "",
          );
        } else {
          final Map<String, dynamic>? credentials = await LocalDbDAO.instance
              .getNetworkCredential(ip: ip);
          yield* repository.fetchAndSaveStocks(
            ip,
            AppGlobals.instance.currentPath ?? "",
            credentials?['username'] as String?,
            credentials?['password'] as String?,
            mobileInfo.deviceId,
            AppGlobals.instance.shopfront ?? "",
          );
        }
      } else {
        yield* Stream.error("Please connect to a network!");
      }
    } catch (error) {
      yield* Stream.error(error);
    }
  }
}
