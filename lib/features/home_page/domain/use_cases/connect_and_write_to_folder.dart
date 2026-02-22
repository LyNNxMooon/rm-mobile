import 'package:rmstock_scanner/features/home_page/domain/repositories/home_repo.dart';

import '../../../../local_db/local_db_dao.dart';
import '../../../../utils/global_var_utils.dart';
import '../../../../utils/internet_connection_utils.dart';
import '../../../../utils/path_check_utils.dart';

class ConnectAndWriteToFolder {
  HomeRepo repository;

  ConnectAndWriteToFolder(this.repository);

  Future<void> call(
    String ip,
    String? hostName,
    String fullPath,
    String? userName,
    String? pwd,
  ) async {
    try {
      if (await InternetConnectionUtils.instance.checkInternetConnection()) {
        //check if required cred

        if (userName != null && pwd != null) {
          LocalDbDAO.instance.removeNetworkCredential(ip: ip);

          if ((userName).isNotEmpty && (pwd).isNotEmpty) {
            LocalDbDAO.instance.saveNetworkCredential(
              ip: ip,
              username: userName,
              password: pwd,
            );
          }

          await repository.connectAndWriteToFolder(ip, fullPath, userName, pwd);
        } else {
          final Map<String, dynamic>? credentials = await LocalDbDAO.instance
              .getNetworkCredential(ip: ip);

          await repository.connectAndWriteToFolder(
            ip,
            fullPath,
            credentials?['username'] as String?,
            credentials?['password'] as String?,
          );
        }

        if (await PathCheckUtils.instance.isPathAlreadyExists(ipAddress: ip)) {
          LocalDbDAO.instance.updatePathByIp(
            ip: ip,
            selectedPath: "//$ip/$fullPath",
          );
        } else {
          LocalDbDAO.instance.addNetworkPath(
            "//$ip/$fullPath",
            '',
            hostName ?? "UnknownServer($ip)",
          );
        }

        AppGlobals.instance.currentHostIp = ip;
        AppGlobals.instance.hostName = hostName ?? "UnknownServer($ip)";
        AppGlobals.instance.currentPath = "//$ip/$fullPath";
      } else {
        return Future.error("Please connect to a network!");
      }
    } catch (error) {
      return Future.error(error);
    }
  }
}
