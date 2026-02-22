import 'package:rmstock_scanner/features/home_page/domain/repositories/home_repo.dart';
import '../../../../local_db/local_db_dao.dart';
import '../../../../utils/global_var_utils.dart';
import '../../../../utils/internet_connection_utils.dart';
import '../../../../utils/log_utils.dart';
import '../../../../utils/path_check_utils.dart';

class AutoConnectToDefaultFolder {
  final HomeRepo repository;

  AutoConnectToDefaultFolder(this.repository);

  Future<void> call(String ip, String? hostName) async {
    try {
      if (await InternetConnectionUtils.instance.checkInternetConnection()) {
        String sharedFolder = AppGlobals.instance.defaultLanFolder;
        String defaultUserName = AppGlobals.instance.defaultUserName;
        String defaultPwd = AppGlobals.instance.defaultPwd;


         final Map<String, dynamic>? credentials = await LocalDbDAO.instance
            .getNetworkCredential(ip: ip);

        logger.d(
          "Saved Creds checking in auto connection: ${credentials?['username']}",
        );
        await repository.connectAndWriteToFolder(
          ip,
          "//$ip/$sharedFolder",
          defaultUserName,
          defaultPwd,
        );

        if (await PathCheckUtils.instance.isPathAlreadyExists(ipAddress: ip)) {
          LocalDbDAO.instance.updatePathByIp(
            ip: ip,
            selectedPath: "//$ip/$sharedFolder",
          );
        } else {
          LocalDbDAO.instance.addNetworkPath(
            "//$ip/$sharedFolder",
            '',
            hostName ?? "UnknownServer($ip)",
          );
        }

        AppGlobals.instance.currentHostIp = ip;
        AppGlobals.instance.hostName = hostName ?? "UnknownServer($ip)";
        AppGlobals.instance.currentPath = "//$ip/$sharedFolder";

        logger.d("Use case for auto connection was triggered");
      } else {
        return Future.error("Please connect to a network!");
      }
    } catch (error) {
      return Future.error(error);
    }
  }
}
