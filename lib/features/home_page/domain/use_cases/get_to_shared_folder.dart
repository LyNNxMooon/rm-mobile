import 'package:rmstock_scanner/features/home_page/domain/repositories/home_repo.dart';

import '../../../../local_db/local_db_dao.dart';
import '../../../../utils/internet_connection_utils.dart';
import '../../../../utils/network_credentials_check_utils.dart';

class GetToSharedFolder {
  final HomeRepo repository;

  GetToSharedFolder(this.repository);

  Future<List<String>> call(
    String ip,
    String path,
    String? userName,
    String? pwd,
  ) async {
    try {
      if (await InternetConnectionUtils.instance.checkInternetConnection()) {
        //check if required cred
        if (await NetworkCredentialsCheckUtils.instance
            .isRequiredNetworkCredentials(ipAddress: ip)) {
          final Map<String, dynamic>? credentials = await LocalDbDAO.instance
              .getNetworkCredential(ip: ip);

          return repository.getDirectoryList(
            ip,
            path,
            credentials?['username'] as String?,
            credentials?['password'] as String?,
          );
        } else {
          LocalDbDAO.instance.removeNetworkCredential(ip: ip);

          if ((userName ?? '').isNotEmpty && (pwd ?? '').isNotEmpty) {
            LocalDbDAO.instance.saveNetworkCredential(
              ip: ip,
              username: userName ?? "Guest",
              password: pwd ?? "",
            );
          }

          return repository.getDirectoryList(ip, path, userName, pwd);
        }
      } else {
        return Future.error("Please connect to a network!");
      }
    } catch (error) {
      return Future.error(error);
    }
  }
}
