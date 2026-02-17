import 'package:rmstock_scanner/features/loading_splash/domain/repositories/loading_splash_repo.dart';

import '../../../../local_db/local_db_dao.dart';
import '../../../../utils/global_var_utils.dart';
import '../../../../utils/internet_connection_utils.dart';
import '../../../../utils/log_utils.dart';

class CheckPathConnection {
  final LoadingSplashRepo repository;

  CheckPathConnection(this.repository);

  Future<bool> call(String path) async {
    try {
      final savedIp = await LocalDbDAO.instance.getHostIpAddress();
      final savedPort = await LocalDbDAO.instance.getHostPort();
      final savedApiKey = await LocalDbDAO.instance.getApiKey();
      final savedHostName = await LocalDbDAO.instance.getHostName();
      final savedShopfrontName = await LocalDbDAO.instance.getShopfrontName();

      if ((savedIp ?? "").isEmpty ||
          (savedPort ?? "").isEmpty ||
          (savedApiKey ?? "").isEmpty) {
        return false;
      }

      final int? port = int.tryParse(savedPort!);
      if (port == null || port <= 0 || port > 65535) {
        return false;
      }

      try {
        if (await InternetConnectionUtils.instance.checkInternetConnection()) {
          final isValid = await repository.validateConnection(
            ip: savedIp!,
            port: port,
            apiKey: savedApiKey!,
          );

          if (!isValid) return false;

          AppGlobals.instance.currentHostIp = savedIp;
          AppGlobals.instance.hostName = savedHostName ?? savedIp;
          AppGlobals.instance.shopfront = savedShopfrontName;

          logger.d('Init validating connection was completed');
          return true;

          // Old setup disabled:
          // AppGlobals.instance.currentPath = result['path'];
          // ... SMB credential/path checks via repository.checksConnection(...)
        } else {
          return Future.error("Please connect to a network!");
        }
      } on Exception catch (_) {
        return false;
      }
    } catch (error) {
      return Future.error(error);
    }
  }
}
