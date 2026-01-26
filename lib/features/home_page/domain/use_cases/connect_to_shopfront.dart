import 'package:rmstock_scanner/features/home_page/domain/repositories/home_repo.dart';

import '../../../../entities/vos/device_metedata_vo.dart';
import '../../../../local_db/local_db_dao.dart';
import '../../../../utils/device_meta_data_utils.dart';
import '../../../../utils/global_var_utils.dart';
import '../../../../utils/internet_connection_utils.dart';

class ConnectToShopfront {
  final HomeRepo repository;

  ConnectToShopfront(this.repository);

  Future<void> call(
    String ip,
    String selectedShopfront,
    String? userName,
    String? pwd,
  ) async {
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

          await repository.connectToShopfronts(
            ip,
            AppGlobals.instance.currentPath ?? "",
            userName,
            pwd,
            selectedShopfront,
            mobileInfo.deviceId,
            mobileInfo.name,
          );
        } else {
          final Map<String, dynamic>? credentials = await LocalDbDAO.instance
              .getNetworkCredential(ip: ip);

          await repository.connectToShopfronts(
            ip,
            AppGlobals.instance.currentPath ?? "",
            credentials?['username'] as String?,
            credentials?['password'] as String?,
            selectedShopfront,
            mobileInfo.deviceId,
            mobileInfo.name,
          );
        }

        AppGlobals.instance.shopfront = selectedShopfront;
      } else {
        return Future.error("Please connect to a network!");
      }
    } catch (error) {
      return Future.error(error);
    }
  }
}
