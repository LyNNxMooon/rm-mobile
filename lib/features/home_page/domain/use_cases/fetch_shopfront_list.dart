import 'package:rmstock_scanner/entities/response/shopfront_response.dart';
import 'package:rmstock_scanner/features/home_page/domain/repositories/home_repo.dart';

import '../../../../local_db/local_db_dao.dart';
import '../../../../utils/internet_connection_utils.dart';
import '../../../../utils/network_credentials_check_utils.dart';

class FetchShopfrontList {
  final HomeRepo repository;

  FetchShopfrontList(this.repository);

  Future<ShopfrontResponse> call(
    String ip,
    String fullPath,
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

          return await repository.fetchShopfronts(
            ip,
            fullPath,
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

          return await repository.fetchShopfronts(ip, fullPath, userName, pwd);
        }
      } else {
        return Future.error("Please connect to a network!");
      }
    } catch (error) {
      return Future.error(error);
    }
  }
}
