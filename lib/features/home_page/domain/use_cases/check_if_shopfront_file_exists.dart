import 'package:rmstock_scanner/features/home_page/domain/repositories/home_repo.dart';

import '../../../../local_db/local_db_dao.dart';
import '../../../../utils/network_credentials_check_utils.dart';

class CheckIfShopfrontFileExists {
  final HomeRepo repository;

  CheckIfShopfrontFileExists(this.repository);

  Future<bool> call(
    String ip,
    String fullPath,
    String? userName,
    String? pwd,
  ) async {
    try {
      if (await NetworkCredentialsCheckUtils.instance
          .isRequiredNetworkCredentials(ipAddress: ip)) {
        final Map<String, dynamic>? credentials = await LocalDbDAO.instance
            .getNetworkCredential(ip: ip);
        return await repository.isShopfrontFileExists(
          ip,
          fullPath,
          credentials?['username'] as String?,
          credentials?['password'] as String?,
        );
      } else {
        return await repository.isShopfrontFileExists(
          ip,
          fullPath,
          userName,
          pwd,
        );
      }
    } catch (error) {
      return false;
    }
  }
}
