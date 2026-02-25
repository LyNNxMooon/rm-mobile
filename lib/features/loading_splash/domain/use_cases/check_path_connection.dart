import 'dart:convert';

import 'package:rmstock_scanner/features/loading_splash/domain/repositories/loading_splash_repo.dart';

import '../../../../local_db/local_db_dao.dart';
import '../../../../local_db/sqlite/sqlite_constants.dart';
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
          AppGlobals.instance.securityEnabled =
              ((await LocalDbDAO.instance.getAppConfig(kSecurityEnabledKey)) ??
                  "1") ==
              "1";

          final String savedStaffId =
              ((await LocalDbDAO.instance.getAppConfig(kStaffIdKey)) ?? "")
                  .trim();
          final String savedStaffNo =
              ((await LocalDbDAO.instance.getAppConfig(kStaffNoKey)) ?? "")
                  .trim();
          final String savedStaffName =
              ((await LocalDbDAO.instance.getAppConfig(kStaffNameKey)) ?? "")
                  .trim();
          final String savedGroupIds =
              ((await LocalDbDAO.instance.getAppConfig(kStaffGroupIdsKey)) ??
                      "[]")
                  .trim();
          final String savedGroupNames =
              ((await LocalDbDAO.instance.getAppConfig(kStaffGroupNamesKey)) ??
                      "[]")
                  .trim();
          final String savedGranted =
              ((await LocalDbDAO.instance.getAppConfig(
                        kStaffGrantedPermissionsKey,
                      )) ??
                      "[]")
                  .trim();
          final String savedRestricted =
              ((await LocalDbDAO.instance.getAppConfig(
                        kStaffRestrictedPermissionsKey,
                      )) ??
                      "[]")
                  .trim();

          if (savedStaffNo.isNotEmpty && savedStaffName.isNotEmpty) {
            AppGlobals.instance.staffId = int.tryParse(savedStaffId);
            AppGlobals.instance.staffNo = savedStaffNo;
            AppGlobals.instance.staffName = savedStaffName;
            AppGlobals.instance.staffGroupIds =
                (jsonDecode(savedGroupIds) as List<dynamic>)
                    .map((e) => (e as num).toInt())
                    .toList();
            AppGlobals.instance.staffGroupNames =
                (jsonDecode(savedGroupNames) as List<dynamic>).cast<String>();
            AppGlobals.instance.grantedPermissions =
                (jsonDecode(savedGranted) as List<dynamic>)
                    .cast<String>()
                    .toSet();
            AppGlobals.instance.restrictedPermissions =
                (jsonDecode(savedRestricted) as List<dynamic>)
                    .cast<String>()
                    .toSet();
          } else {
            AppGlobals.instance.clearStaffSession();
          }

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
