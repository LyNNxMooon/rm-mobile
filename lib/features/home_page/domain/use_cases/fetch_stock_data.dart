import 'package:rmstock_scanner/features/home_page/domain/repositories/home_repo.dart';

import '../../../../entities/vos/device_metedata_vo.dart';
import '../../../../local_db/local_db_dao.dart';
import '../../../../utils/device_meta_data_utils.dart';
import '../../../../utils/global_var_utils.dart';
import '../../../../utils/internet_connection_utils.dart';
import '../../../../utils/network_credentials_check_utils.dart';
import '../../models/home_screen_models.dart';

class FetchStockData {
  final HomeRepo repository;

  FetchStockData(this.repository);

  Stream<SyncStatus> call(String ip, String? userName, String? pwd) async* {
    try {
      if (await InternetConnectionUtils.instance.checkInternetConnection()) {
        final DeviceMetadata mobileInfo = await DeviceMetaDataUtils.instance
            .getDeviceInformation();

        String? finalUser = userName;
        String? finalPwd = pwd;

        if (await NetworkCredentialsCheckUtils.instance
            .isRequiredNetworkCredentials(ipAddress: ip)) {
          final Map<String, dynamic>? credentials = await LocalDbDAO.instance
              .getNetworkCredential(ip: ip);
          finalUser = credentials?['username'] as String?;
          finalPwd = credentials?['password'] as String?;
        }

        yield* repository.fetchAndSaveStocks(
          ip,
          AppGlobals.instance.currentPath ?? "",
          finalUser,
          finalPwd,
          mobileInfo.name,
        );
      } else {
        yield* Stream.error("Please connect to a network!");
      }
    } catch (error) {
      yield* Stream.error(error);
    }
  }
}
