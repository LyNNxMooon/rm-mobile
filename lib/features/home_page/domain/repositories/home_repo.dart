import 'package:rmmobile/entities/response/discover_response.dart';
import 'package:rmmobile/entities/response/authenticate_staff_response.dart';
import 'package:rmmobile/entities/response/paircode_response.dart';
import 'package:rmmobile/entities/response/pair_response.dart';
import 'package:rmmobile/entities/response/connect_shopfront_response.dart';
import 'package:rmmobile/entities/response/security_groups_response.dart';
import 'package:rmmobile/entities/response/shopfront_response.dart';

import '../../../../entities/vos/network_server_vo.dart';

abstract class HomeRepo {
  Future<List<NetworkServerVO>> fetchNetworkServers();
  Future<List<String>> getDirectoryList(
    String address,
    String path,
    String? userName,
    String? pwd,
  );
  Future<void> connectAndWriteToFolder(
    String address,
    String fullPath,
    String? userName,
    String? pwd,
  );

  Future<bool> isShopfrontFileExists(
    String address,
    String path,
    String? userName,
    String? pwd,
  );

  Future<ShopfrontResponse> fetchShopfronts(
    String address,
    String fullPath,
    String? userName,
    String? pwd,
  );

  Future<void> connectToShopfronts(
    String ipAddress,
    String fullPath,
    String? username,
    String? password,
    String selectedShopfront,
    String mobileID,
    String mobileName,
  );

  Future<int> getRetentionDays();

  Future<void> setRetentionDays(int days);

  Future<int> runHistoryCleanup();

  Future<bool> getAutoBackupEnabled();

  Future<void> setAutoBackupEnabled(bool enabled);

  Future<bool> getDarkModeEnabled();

  Future<void> setDarkModeEnabled(bool enabled);

  Future<DateTime?> getLastAutoBackupAt();

  Future<void> setLastAutoBackupAt(DateTime timestamp);

  Future<DiscoverResponse> discoverHost(String ip, int port);

  Future<PaircodeResponse> getPairCodes(String ip, int port);

  Future<PairResponse> pairDevice({
    required String ip,
    required String hostName,
    required int port,
    required String pairingCode,
  });

  Future<ShopfrontResponse> fetchShopfrontsFromApi(
    String ip,
    int port,
    String apiKey,
  );

  Future<ConnectShopfrontResponse> connectShopfrontFromApi({
    required String ip,
    required int port,
    required String apiKey,
    required String shopfrontId,
    required String shopfrontName,
  });

  Future<AuthenticateStaffResponse> authenticateStaff({
    required String ip,
    required int port,
    required String apiKey,
    required String shopfrontId,
    required String shopfrontName,
    required String staffNo,
    required String password,
  });

  Future<SecurityGroupsResponse> fetchSecurityGroups({
    required String ip,
    required int port,
    required String apiKey,
    required String shopfrontId,
  });

  Future<bool> loadSavedStaffSession();

  Future<void> signOutStaff();

  Future<SavedConnectionInfo> loadSavedConnectionInfo();

  Future<SavedStaffCredentials> loadSavedStaffCredentials();

  Future<String?> getCashDrawerIdentifier();

  Future<void> saveCashDrawerIdentifier(String identifier);

  Future<String?> getRmVersion();

  Future<void> checkpointDatabase();

  Future<String> getDatabasePath();

  Future<void> closeDatabase();

  Future<void> reopenDatabase();

  Future<void> clearSyncTimestamps(String shopfrontId);

  Future<Map<String, int>> getSaleSessionCounts(String shopfront);

  Future<Map<String, Map<String, dynamic>>> getSaleSessionSummaries(String shopfront);
}

class SavedConnectionInfo {
  final int? port;
  final String apiKey;
  final String shopfrontId;
  final String shopfrontName;

  SavedConnectionInfo({
    required this.port,
    required this.apiKey,
    required this.shopfrontId,
    required this.shopfrontName,
  });
}

class SavedStaffCredentials {
  final String staffNo;
  final String password;

  SavedStaffCredentials({
    required this.staffNo,
    required this.password,
  });
}
