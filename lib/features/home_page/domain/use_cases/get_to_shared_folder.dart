import 'package:rmstock_scanner/features/home_page/domain/repositories/home_repo.dart';
import 'package:rmstock_scanner/utils/log_utils.dart';

import '../../../../local_db/local_db_dao.dart';
import '../../../../utils/internet_connection_utils.dart';

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
        if (userName != null && pwd != null) {
          LocalDbDAO.instance.removeNetworkCredential(ip: ip);

          if ((userName).isNotEmpty && (pwd).isNotEmpty) {
            LocalDbDAO.instance.saveNetworkCredential(
              ip: ip,
              username: userName,
              password: pwd,
            );
          }

          return repository.getDirectoryList(ip, path, userName, pwd);
        } else {
          final Map<String, dynamic>? credentials = await LocalDbDAO.instance
              .getNetworkCredential(ip: ip);

          logger.d("We were here with saved cred! ${credentials?['password']}");

          return repository.getDirectoryList(
            ip,
            path,
            credentials?['username'] as String?,
            credentials?['password'] as String?,
          );
        }
      } else {
        return Future.error("Please connect to a network!");
      }
    } catch (error) {
      return Future.error(error);
    }
  }
}
