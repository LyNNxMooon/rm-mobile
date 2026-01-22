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




        await repository.connectAndWriteToFolder(
          ip,
          "//$ip/Users/Public/AAAPOS RM-Mobile",
          "Guest",
          ""
        );

        if (await PathCheckUtils.instance.isPathAlreadyExists(ipAddress: ip)) {
          LocalDbDAO.instance.updatePathByIp(
            ip: ip,
            selectedPath: "//$ip/Users/Public/AAAPOS RM-Mobile",
          );
        } else {
          LocalDbDAO.instance.addNetworkPath(
            "//$ip/Users/Public/AAAPOS RM-Mobile",
            '',
            hostName ?? "UnknownPC($ip)",
          );
        }

        AppGlobals.instance.currentHostIp = ip;
        AppGlobals.instance.hostName = hostName ?? "UnknownPC($ip)";
        AppGlobals.instance.currentPath = "//$ip/Users/Public/AAAPOS RM-Mobile";

        logger.d("Use case for auto connection was triggered");
      } else {
        return Future.error("Please connect to a network!");
      }
    } catch (error) {
      return Future.error(error);
    }
  }
}
