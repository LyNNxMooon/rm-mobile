import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:rmstock_scanner/entities/response/shopfront_response.dart';
import 'package:rmstock_scanner/entities/vos/network_computer_vo.dart';
import 'package:rmstock_scanner/entities/vos/stock_vo.dart';
import 'package:rmstock_scanner/features/home_page/domain/repositories/home_repo.dart';
import 'package:rmstock_scanner/utils/log_utils.dart';
import 'package:smb_connect/smb_connect.dart';

import '../../../local_db/local_db_dao.dart';
import '../../../network/LAN_sharing/lan_network_service_impl.dart';
import '../../../utils/global_var_utils.dart';

class HomeScreenModels implements HomeRepo {
  //Data manipulation can be done here (E.g. substituting data for null values returned from API)

  @override
  Future<List<NetworkComputerVO>> fetchNetworkPCs() async {
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
  Stream<SyncStatus> fetchAndSaveStocks(
    String ipAddress,
    String fullPath,
    String? username,
    String? password,
    String mobileID,
    String shopfront,
  ) async* {
    final sanitizedName = mobileID.replaceAll(" ", "_");

    yield SyncStatus(0, 0, "Waiting for agent...");

    final firstFile = await LanNetworkServiceImpl.instance.pollForFile(
      address: ipAddress,
      fullPath: fullPath,
      username: username ?? AppGlobals.instance.defaultUserName,
      password: password ?? AppGlobals.instance.defaultPwd,
      fileNamePattern: "${sanitizedName}_stocklookup_part1_of_",
      maxRetries: 60,
    );

    if (firstFile == null) {
      throw Exception("RM-Mobile Manager did not respond in time.");
    }

    final nameParts = firstFile.name.split('_');
    int totalParts = 1;
    String timestamp = "";

    try {
      int ofIndex = nameParts.indexOf("of");
      totalParts = int.parse(nameParts[ofIndex + 1]);
      timestamp = nameParts[ofIndex + 2].split('.')[0];
    } catch (e) {
      totalParts = 1;
    }

    yield SyncStatus(0, totalParts * 10000, "Starting Sync...");

    final String shopKey = shopfront;
    // IMPORTANT: Only clear the whole database if it is a FULL SYNC
    // If it's a Delta Sync, do NOT call clearStocksForShop.
    final String? lastSync = await LocalDbDAO.instance.getAppConfig(shopKey);
    if (lastSync == null || lastSync.isEmpty) {
      await LocalDbDAO.instance.clearStocksForShop(
        AppGlobals.instance.shopfront ?? "",
      );
    }

    for (int i = 1; i <= totalParts; i++) {
      String partPattern = "part${i}_of_${totalParts}_$timestamp";

      SmbFile? currentFile;
      if (i == 1) {
        currentFile = firstFile;
      } else {
        currentFile = await LanNetworkServiceImpl.instance.pollForFile(
          address: ipAddress,
          fullPath: fullPath,
          username: username ?? AppGlobals.instance.defaultUserName,
          password: password ?? AppGlobals.instance.defaultPwd,
          fileNamePattern: partPattern,
          maxRetries: 60,
        );
      }

      if (currentFile == null) {
        throw Exception("Timeout waiting for $partPattern");
      }

      Uint8List bytes = await LanNetworkServiceImpl.instance
          .downloadAndDeleteFile(
            address: ipAddress,
            username: username ?? AppGlobals.instance.defaultUserName,
            password: password ?? AppGlobals.instance.defaultPwd,
            fileToDownload: currentFile,
          );

      String jsonString = utf8.decode(GZipCodec().decode(bytes));
      List<StockVO> chunk = (jsonDecode(jsonString) as List)
          .map((e) => StockVO.fromJsonNetwork(e))
          .toList();

      await LocalDbDAO.instance.insertStocks(
        chunk,
        AppGlobals.instance.shopfront ?? "",
      );

      int approximateTotal = totalParts * 10000;
      int currentCount = i * 10000;
      if (i == totalParts) currentCount = approximateTotal;

      yield SyncStatus(
        currentCount,
        approximateTotal,
        "Syncing part $i of $totalParts...",
      );
    }
    final String completionTime = DateTime.now().toString();
    await LocalDbDAO.instance.saveAppConfig(shopKey, completionTime);
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

class SyncStatus {
  final int processed;
  final int total;
  final String message;

  SyncStatus(this.processed, this.total, this.message);
}
