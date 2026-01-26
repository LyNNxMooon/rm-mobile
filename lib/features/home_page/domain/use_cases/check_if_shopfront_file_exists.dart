import 'package:rmstock_scanner/features/home_page/domain/repositories/home_repo.dart';
import 'package:rmstock_scanner/utils/log_utils.dart';

import '../../../../local_db/local_db_dao.dart';

class CheckIfShopfrontFileExists {
  final HomeRepo repository;

  CheckIfShopfrontFileExists(this.repository);

  Future<bool> call(
    String ip,
    String fullPath,
    String? userName,
    String? pwd,
  ) async {
    logger.d(
      "Checking cred in use case for checking if shopfront exists: $userName / $pwd",
    );
    try {
      if (userName != null && pwd != null) {
        LocalDbDAO.instance.removeNetworkCredential(ip: ip);

        if ((userName).isNotEmpty && (pwd).isNotEmpty) {
          LocalDbDAO.instance.saveNetworkCredential(
            ip: ip,
            username: userName,
            password: pwd,
          );
        }

        logger.d("Triggered with inputted ones");
        return await repository.isShopfrontFileExists(
          ip,
          fullPath,
          userName,
          pwd,
        );
      } else {
        logger.d("Triggered with saved ones");

        final Map<String, dynamic>? credentials = await LocalDbDAO.instance
            .getNetworkCredential(ip: ip);
        return await repository.isShopfrontFileExists(
          ip,
          fullPath,
          credentials?['username'] as String?,
          credentials?['password'] as String?,
        );
      }
    } catch (error) {
      return false;
    }
  }
}
