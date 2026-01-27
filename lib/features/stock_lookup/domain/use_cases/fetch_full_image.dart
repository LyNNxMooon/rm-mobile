import 'package:rmstock_scanner/features/stock_lookup/domain/repositories/stock_lookup_repo.dart';
import 'package:rmstock_scanner/local_db/local_db_dao.dart';
import 'package:rmstock_scanner/utils/global_var_utils.dart';
import 'package:rmstock_scanner/utils/network_credentials_check_utils.dart';

class FetchFullImage {
  final StockLookupRepo repository;

  FetchFullImage(this.repository);

  Future<String?> call({required String pictureFileName}) async {
    try {
      String? finalUser;
      String? finalPwd;

      if (await NetworkCredentialsCheckUtils.instance
          .isRequiredNetworkCredentials(
            ipAddress: AppGlobals.instance.currentHostIp ?? "",
          )) {
        final credentials = await LocalDbDAO.instance.getNetworkCredential(
          ip: AppGlobals.instance.currentHostIp ?? "",
        );
        finalUser = credentials?['username'] as String?;
        finalPwd = credentials?['password'] as String?;
      }

      final String shopfrontName = (AppGlobals.instance.shopfront ?? "")
          .split(r'\')
          .last;

      return repository.fetchAndCacheFullImagePath(
        address: AppGlobals.instance.currentHostIp ?? "",
        fullPath: AppGlobals.instance.currentPath ?? "",
        username: finalUser,
        password: finalPwd,
        shopfrontName: shopfrontName,
        pictureFileName: pictureFileName,
      );
    } catch (error) {
      return Future.error(error);
    }
  }
}
