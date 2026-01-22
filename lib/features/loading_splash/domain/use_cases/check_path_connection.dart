import 'package:rmstock_scanner/features/loading_splash/domain/repositories/loading_splash_repo.dart';

import '../../../../local_db/local_db_dao.dart';
import '../../../../utils/global_var_utils.dart';
import '../../../../utils/internet_connection_utils.dart';
import '../../../../utils/log_utils.dart';
import '../../../../utils/network_credentials_check_utils.dart';

class CheckPathConnection {
  final LoadingSplashRepo repository;

  CheckPathConnection(this.repository);

  Future<bool> call(String path) async {
    try {
      Map<String, dynamic>? result = await LocalDbDAO.instance
          .getSingleNetworkPath(path);

      if (result == null) {
        return false;
      } else {
        String shopfront = result['shopfront'];

        if (shopfront.isEmpty) {
          return false;
        } else {
          final regex = RegExp(r'//(\d{1,3}(?:\.\d{1,3}){3})');
          final match = regex.firstMatch(result['path']);

          final ipAddress = match?.group(1);

          try {
            if (await InternetConnectionUtils.instance
                .checkInternetConnection()) {
              AppGlobals.instance.currentHostIp = ipAddress ?? "";
              AppGlobals.instance.currentPath = result['path'];
              AppGlobals.instance.shopfront = shopfront;
              AppGlobals.instance.hostName = result['host_name'];

              if (await NetworkCredentialsCheckUtils.instance
                  .isRequiredNetworkCredentials(ipAddress: ipAddress ?? "")) {
                final Map<String, dynamic>? credentials = await LocalDbDAO
                    .instance
                    .getNetworkCredential(ip: ipAddress ?? "");

                await repository
                    .checksConnection(
                      ipAddress ?? "",
                      result['path'],
                      credentials?['username'] as String?,
                      credentials?['password'] as String?,
                    )
                    .then((_) {
                      logger.d('Init Checking connection was completed');
                    });

                return true;
              } else {
                await repository
                    .checksConnection(
                      ipAddress ?? "",
                      result['path'],
                      null,
                      null,
                    )
                    .then((_) {
                      logger.d('Init Checking connection was completed');
                    });

                return true;
              }
            } else {
              return Future.error("Please connect to a network!");
            }
          } on Exception catch (_) {
            return false;
          }
        }
      }
    } catch (error) {
      return Future.error(error);
    }
  }
}
