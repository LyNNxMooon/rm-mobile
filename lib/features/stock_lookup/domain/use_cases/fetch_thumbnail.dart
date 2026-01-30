import 'package:rmstock_scanner/features/stock_lookup/domain/repositories/stock_lookup_repo.dart';
import 'package:rmstock_scanner/local_db/local_db_dao.dart';
import 'package:rmstock_scanner/utils/global_var_utils.dart';
import 'package:rmstock_scanner/utils/network_credentials_check_utils.dart';

class FetchThumbnail {
  final StockLookupRepo repository;

  FetchThumbnail(this.repository);

  Future<String?> call({
    required String pictureFileName,
    required bool forceRefresh,
  }) async {
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

      //fullPath.split(r'\').last

      return repository.fetchAndCacheThumbnailPath(
        address: AppGlobals.instance.currentHostIp ?? "",
        fullPath: AppGlobals.instance.currentPath ?? "",
        username: finalUser,
        password: finalPwd,
        shopfrontName: shopfrontName,
        pictureFileName: pictureFileName,
        forceRefresh: forceRefresh
      );
    } catch (error) {
      return Future.error(error);
    }
  }
}
