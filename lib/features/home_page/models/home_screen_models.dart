import 'dart:convert';

import 'package:rmstock_scanner/entities/response/discover_response.dart';
import 'package:rmstock_scanner/entities/response/authenticate_staff_response.dart';
import 'package:rmstock_scanner/entities/response/connect_shopfront_response.dart';
import 'package:rmstock_scanner/entities/response/paircode_response.dart';
import 'package:rmstock_scanner/entities/response/pair_response.dart';
import 'package:rmstock_scanner/entities/response/security_groups_response.dart';
import 'package:rmstock_scanner/entities/response/shopfront_response.dart';
import 'package:rmstock_scanner/entities/vos/network_server_vo.dart';
import 'package:rmstock_scanner/features/home_page/domain/repositories/home_repo.dart';
import 'package:rmstock_scanner/network/data_agent/data_agent_impl.dart';
import 'package:rmstock_scanner/utils/log_utils.dart';

import '../../../local_db/local_db_dao.dart';
import '../../../local_db/sqlite/sqlite_constants.dart';
import '../../../network/LAN_sharing/lan_network_service_impl.dart';
import '../../../utils/device_meta_data_utils.dart';
import '../../../utils/global_var_utils.dart';

class HomeScreenModels implements HomeRepo {
  //Data manipulation can be done here (E.g. substituting data for null values returned from API)
  static const String _kAutoBackupEnabledKey = "auto_backup_enabled";
  static const String _kLastAutoBackupAtKey = "last_auto_backup_at";

  @override
  Future<List<NetworkServerVO>> fetchNetworkServers() async {
    try {
      return LanNetworkServiceImpl.instance.scanNetwork();
    } on Exception catch (error) {
      return Future.error(error);
    }
  }

  @override
  Future<List<String>> getDirectoryList(
    String address,
    String path,
    String? userName,
    String? pwd,
  ) {
    try {
      return LanNetworkServiceImpl.instance.getDirectoryListing(
        address: address,
        path: path,
        username: userName ?? AppGlobals.instance.defaultUserName,
        password: pwd ?? AppGlobals.instance.defaultPwd,
      );
    } on Exception catch (error) {
      return Future.error(error);
    }
  }

  @override
  Future<void> connectAndWriteToFolder(
    String address,
    String fullPath,
    String? userName,
    String? pwd,
  ) {
    try {
      return LanNetworkServiceImpl.instance.writeToSelectedFolder(
        address: address,
        fullPath: fullPath,
        username: userName ?? AppGlobals.instance.defaultUserName,
        password: pwd ?? AppGlobals.instance.defaultPwd,
      );
    } on Exception catch (error) {
      return Future.error(error);
    }
  }

  @override
  Future<ShopfrontResponse> fetchShopfronts(
    String address,
    String fullPath,
    String? userName,
    String? pwd,
  ) async {
    try {
      logger.d("Model SF Path: $fullPath");

      return LanNetworkServiceImpl.instance.getShopfronts(
        address: address,
        fullPath: fullPath,
        username: userName ?? AppGlobals.instance.defaultUserName,
        password: pwd ?? AppGlobals.instance.defaultPwd,
      );
    } on Exception catch (error) {
      return Future.error(error);
    }
  }

  @override
  Future<void> connectToShopfronts(
    String ipAddress,
    String fullPath,
    String? username,
    String? password,
    String selectedShopfront,
    String mobileID,
    String mobileName,
  ) async {
    try {
      final String shopKey = selectedShopfront;

      String? lastSyncTime = await LocalDbDAO.instance.getAppConfig(shopKey);

      final String jsonContent = _StockRequestJsonBuilder.buildJson(
        mobileID,
        mobileName,
        selectedShopfront,
        lastSyncTime,
      );

      final now = DateTime.now();

      String pad(int value) => value.toString().padLeft(2, '0');

      final String timestamp =
          "${now.year}"
          "${pad(now.month)}"
          "${pad(now.day)}"
          "${pad(now.hour)}"
          "${pad(now.minute)}"
          "${pad(now.second)}";

      final String fileName = "${mobileID}_request_$timestamp.json";

      await LanNetworkServiceImpl.instance.sendStockRequest(
        address: ipAddress,
        fullPath: fullPath,
        username: username ?? AppGlobals.instance.defaultUserName,
        password: password ?? AppGlobals.instance.defaultPwd,
        fileName: fileName,
        fileContent: jsonContent,
        mobileID: mobileID,
      );

      await LocalDbDAO.instance.updateShopfrontByIp(
        ip: ipAddress,
        selectedShopfront: selectedShopfront,
      );
    } on Exception catch (error) {
      return Future.error(error);
    }
  }

  @override
  Future<bool> isShopfrontFileExists(
    String address,
    String path,
    String? userName,
    String? pwd,
  ) async {
    try {
      return LanNetworkServiceImpl.instance.isShopfrontsFileExists(
        address: address,
        fullPath: path,
        username: userName ?? AppGlobals.instance.defaultUserName,
        password: pwd ?? AppGlobals.instance.defaultPwd,
      );
    } on Exception catch (_) {
      return false;
    }
  }

  @override
  Future<int> getRetentionDays() {
    return LocalDbDAO.instance.getHistoryRetentionDays();
  }

  @override
  Future<void> setRetentionDays(int days) {
    return LocalDbDAO.instance.setHistoryRetentionDays(days);
  }

  @override
  Future<int> runHistoryCleanup() {
    return LocalDbDAO.instance.cleanupHistoryByRetention();
  }

  @override
  Future<bool> getAutoBackupEnabled() async {
    try {
      final raw = await LocalDbDAO.instance.getAppConfig(
        _kAutoBackupEnabledKey,
      );
      if (raw == null || raw.isEmpty) return true;
      return raw == "1";
    } on Exception catch (error) {
      return Future.error(error);
    }
  }

  @override
  Future<void> setAutoBackupEnabled(bool enabled) async {
    try {
      await LocalDbDAO.instance.saveAppConfig(
        _kAutoBackupEnabledKey,
        enabled ? "1" : "0",
      );
    } on Exception catch (error) {
      return Future.error(error);
    }
  }

  @override
  Future<DateTime?> getLastAutoBackupAt() async {
    try {
      final raw = await LocalDbDAO.instance.getAppConfig(_kLastAutoBackupAtKey);
      if (raw == null || raw.isEmpty) return null;
      return DateTime.tryParse(raw);
    } on Exception catch (error) {
      return Future.error(error);
    }
  }

  @override
  Future<void> setLastAutoBackupAt(DateTime timestamp) async {
    try {
      await LocalDbDAO.instance.saveAppConfig(
        _kLastAutoBackupAtKey,
        timestamp.toUtc().toIso8601String(),
      );
    } on Exception catch (error) {
      return Future.error(error);
    }
  }

  @override
  Future<DiscoverResponse> discoverHost(String ip, int port) async {
    try {
      final response = await DataAgentImpl.instance.discoverHost(ip, port);
      return response;
    } on Exception catch (error) {
      return Future.error(error);
    }
  }

  @override
  Future<PaircodeResponse> getPairCodes(String ip, int port) async {
    try {
      final response = await DataAgentImpl.instance.getPairCodes(ip, port);
      return response;
    } on Exception catch (error) {
      return Future.error(error);
    }
  }

  @override
  Future<PairResponse> pairDevice({
    required String ip,
    required String hostName,
    required int port,
    required String pairingCode,
  }) async {
    try {
      final mobileInfo = await DeviceMetaDataUtils.instance
          .getDeviceInformation();

      final response = await DataAgentImpl.instance.pairDevice(ip, port, {
        "PairingCode": pairingCode,
        "DeviceName": mobileInfo.name,
        "DeviceType": "Mobile",
      });

      if (response.success) {
        await LocalDbDAO.instance.saveHostIpAddress(ip);
        await LocalDbDAO.instance.saveHostName(hostName);
        await LocalDbDAO.instance.saveHostPort(port.toString());
        await LocalDbDAO.instance.saveApiKey(response.apiKey);
        await LocalDbDAO.instance.saveDeviceId(response.deviceId);

        AppGlobals.instance.currentHostIp = ip;
        AppGlobals.instance.hostName = hostName;
      }

      return response;
    } on Exception catch (error) {
      return Future.error(error);
    }
  }

  @override
  Future<ShopfrontResponse> fetchShopfrontsFromApi(
    String ip,
    int port,
    String apiKey,
  ) async {
    try {
      final response = await DataAgentImpl.instance.getShopfronts(
        ip,
        port,
        apiKey,
      );

      final enabledShopfronts = response.shopfronts
          .where((e) => e.isEnabled)
          .map((e) => e.name)
          .toList();
      final Map<String, String> idMap = {
        for (final s in response.shopfronts.where((e) => e.isEnabled))
          s.name: s.id,
      };
      AppGlobals.instance.pairedShopfrontIdsByName = idMap;

      final assigned = response.shopfronts.where((e) => e.isAssigned).toList();
      if (assigned.isNotEmpty) {
        await LocalDbDAO.instance.saveShopfrontId(assigned.first.id);
        await LocalDbDAO.instance.saveShopfrontName(assigned.first.name);
      } else if (response.assignedShopfrontId != null &&
          response.assignedShopfrontId!.isNotEmpty) {
        await LocalDbDAO.instance.saveShopfrontId(
          response.assignedShopfrontId!,
        );
      }

      return ShopfrontResponse(
        total: enabledShopfronts.length,
        shopfronts: enabledShopfronts,
      );
    } on Exception catch (error) {
      return Future.error(error);
    }
  }

  @override
  Future<ConnectShopfrontResponse> connectShopfrontFromApi({
    required String ip,
    required int port,
    required String apiKey,
    required String shopfrontId,
    required String shopfrontName,
  }) async {
    try {
      final response = await DataAgentImpl.instance.connectShopfront(
        ip,
        port,
        shopfrontId,
        apiKey,
      );

      if (response.success) {
        await LocalDbDAO.instance.saveShopfrontId(response.shopfrontId);
        await LocalDbDAO.instance.saveShopfrontName(response.shopfrontName);
        AppGlobals.instance.shopfront = response.shopfrontName;
      }

      return response;
    } on Exception catch (error) {
      return Future.error(error);
    }
  }

  @override
  Future<AuthenticateStaffResponse> authenticateStaff({
    required String ip,
    required int port,
    required String apiKey,
    required String shopfrontId,
    required String shopfrontName,
    required String staffNo,
    required String password,
  }) async {
    try {
      final connectResponse = await DataAgentImpl.instance.connectShopfront(
        ip,
        port,
        shopfrontId,
        apiKey,
      );

      if (!connectResponse.success) {
        return Future.error(connectResponse.message);
      }

      await LocalDbDAO.instance.saveShopfrontId(shopfrontId);
      await LocalDbDAO.instance.saveShopfrontName(shopfrontName);
      AppGlobals.instance.shopfront = shopfrontName;

      final response = await DataAgentImpl.instance.authenticateStaff(
        ip,
        port,
        shopfrontId,
        apiKey,
        <String, dynamic>{"staff_no": staffNo, "password": password},
      );

      await LocalDbDAO.instance.saveAppConfig(
        kSecurityEnabledKey,
        response.securityEnabled ? "1" : "0",
      );
      AppGlobals.instance.securityEnabled = response.securityEnabled;

      if (!response.success || response.staff == null) {
        await signOutStaff();
        return response;
      }

      List<String> resolvedGroupNames = <String>[];
      try {
        final groups = await fetchSecurityGroups(
          ip: ip,
          port: port,
          apiKey: apiKey,
          shopfrontId: shopfrontId,
        );
        final idToName = <int, String>{
          for (final g in groups.groups) g.groupId: g.name,
        };
        resolvedGroupNames = response.groupIds
            .map((id) => idToName[id])
            .whereType<String>()
            .toList();
      } catch (_) {}

      final String fullName =
          "${response.staff!.givenNames} ${response.staff!.surname}".trim();

      final granted = response.grantedPermissions.map((e) => e.name).toList();
      final restricted = response.restrictedPermissions
          .map((e) => e.name)
          .toList();

      await LocalDbDAO.instance.saveAppConfig(
        kStaffIdKey,
        response.staff!.staffId.toString(),
      );
      await LocalDbDAO.instance.saveAppConfig(
        kStaffNoKey,
        response.staff!.staffNo,
      );
      await LocalDbDAO.instance.saveAppConfig(kStaffNameKey, fullName);
      await LocalDbDAO.instance.saveAppConfig(
        kStaffGroupIdsKey,
        jsonEncode(response.groupIds),
      );
      await LocalDbDAO.instance.saveAppConfig(
        kStaffGroupNamesKey,
        jsonEncode(resolvedGroupNames),
      );
      await LocalDbDAO.instance.saveAppConfig(
        kStaffGrantedPermissionsKey,
        jsonEncode(granted),
      );
      await LocalDbDAO.instance.saveAppConfig(
        kStaffRestrictedPermissionsKey,
        jsonEncode(restricted),
      );

      AppGlobals.instance.staffId = response.staff!.staffId;
      AppGlobals.instance.staffNo = response.staff!.staffNo;
      AppGlobals.instance.staffName = fullName;
      AppGlobals.instance.staffGroupIds = response.groupIds;
      AppGlobals.instance.staffGroupNames = resolvedGroupNames;
      AppGlobals.instance.grantedPermissions = granted.toSet();
      AppGlobals.instance.restrictedPermissions = restricted.toSet();

      return response;
    } on Exception catch (error) {
      return Future.error(error);
    }
  }

  @override
  Future<SecurityGroupsResponse> fetchSecurityGroups({
    required String ip,
    required int port,
    required String apiKey,
    required String shopfrontId,
  }) async {
    try {
      return await DataAgentImpl.instance.getSecurityGroups(
        ip,
        port,
        shopfrontId,
        apiKey,
      );
    } on Exception catch (error) {
      return Future.error(error);
    }
  }

  @override
  Future<bool> loadSavedStaffSession() async {
    try {
      final securityEnabledRaw =
          (await LocalDbDAO.instance.getAppConfig(kSecurityEnabledKey) ?? "1")
              .trim();
      final String staffIdRaw =
          (await LocalDbDAO.instance.getAppConfig(kStaffIdKey) ?? "").trim();
      final String staffNo =
          (await LocalDbDAO.instance.getAppConfig(kStaffNoKey) ?? "").trim();
      final String staffName =
          (await LocalDbDAO.instance.getAppConfig(kStaffNameKey) ?? "").trim();
      final String groupIdsJson =
          (await LocalDbDAO.instance.getAppConfig(kStaffGroupIdsKey) ?? "[]")
              .trim();
      final String groupNamesJson =
          (await LocalDbDAO.instance.getAppConfig(kStaffGroupNamesKey) ?? "[]")
              .trim();
      final String grantedJson =
          (await LocalDbDAO.instance.getAppConfig(
                    kStaffGrantedPermissionsKey,
                  ) ??
                  "[]")
              .trim();
      final String restrictedJson =
          (await LocalDbDAO.instance.getAppConfig(
                    kStaffRestrictedPermissionsKey,
                  ) ??
                  "[]")
              .trim();

      AppGlobals.instance.securityEnabled = securityEnabledRaw == "1";

      final List<int> groupIds = (jsonDecode(groupIdsJson) as List<dynamic>)
          .map((e) => (e as num).toInt())
          .toList();
      final List<String> groupNames =
          (jsonDecode(groupNamesJson) as List<dynamic>).cast<String>();
      final Set<String> granted = (jsonDecode(grantedJson) as List<dynamic>)
          .cast<String>()
          .toSet();
      final Set<String> restricted =
          (jsonDecode(restrictedJson) as List<dynamic>).cast<String>().toSet();

      if (staffNo.isEmpty || staffName.isEmpty) {
        AppGlobals.instance.clearStaffSession();
        return false;
      }

      AppGlobals.instance.staffId = int.tryParse(staffIdRaw);
      AppGlobals.instance.staffNo = staffNo;
      AppGlobals.instance.staffName = staffName;
      AppGlobals.instance.staffGroupIds = groupIds;
      AppGlobals.instance.staffGroupNames = groupNames;
      AppGlobals.instance.grantedPermissions = granted;
      AppGlobals.instance.restrictedPermissions = restricted;
      return true;
    } on Exception catch (_) {
      AppGlobals.instance.clearStaffSession();
      return false;
    }
  }

  @override
  Future<void> signOutStaff() async {
    try {
      await LocalDbDAO.instance.saveAppConfig(kStaffIdKey, "");
      await LocalDbDAO.instance.saveAppConfig(kStaffNoKey, "");
      await LocalDbDAO.instance.saveAppConfig(kStaffNameKey, "");
      await LocalDbDAO.instance.saveAppConfig(kStaffGroupIdsKey, "[]");
      await LocalDbDAO.instance.saveAppConfig(kStaffGroupNamesKey, "[]");
      await LocalDbDAO.instance.saveAppConfig(
        kStaffGrantedPermissionsKey,
        "[]",
      );
      await LocalDbDAO.instance.saveAppConfig(
        kStaffRestrictedPermissionsKey,
        "[]",
      );
      AppGlobals.instance.clearStaffSession();
    } on Exception catch (error) {
      return Future.error(error);
    }
  }
}

class _StockRequestJsonBuilder {
  static String buildJson(
    String mobileId,
    String mobileName,
    String shopfrontName,
    String? lastSync,
  ) {
    final requestedDate = DateTime.now();

    final Map<String, dynamic> finalMap = {
      "mobile_device_id": mobileId,
      "mobile_device_name": mobileName,
      "shopfront": shopfrontName,
      "date_requested": requestedDate.toString(),
      "last_sync_timestamp": lastSync ?? "",
    };

    return const JsonEncoder.withIndent('  ').convert(finalMap);
  }
}
