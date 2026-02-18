import 'dart:convert';

import 'package:rmstock_scanner/entities/response/discover_response.dart';
import 'package:rmstock_scanner/entities/response/connect_shopfront_response.dart';
import 'package:rmstock_scanner/entities/response/paircode_response.dart';
import 'package:rmstock_scanner/entities/response/pair_response.dart';
import 'package:rmstock_scanner/entities/response/shopfront_response.dart';
import 'package:rmstock_scanner/entities/vos/network_computer_vo.dart';
import 'package:rmstock_scanner/features/home_page/domain/repositories/home_repo.dart';
import 'package:rmstock_scanner/network/data_agent/data_agent_impl.dart';
import 'package:rmstock_scanner/utils/log_utils.dart';

import '../../../local_db/local_db_dao.dart';
import '../../../network/LAN_sharing/lan_network_service_impl.dart';
import '../../../utils/device_meta_data_utils.dart';
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
      final mobileInfo = await DeviceMetaDataUtils.instance.getDeviceInformation();

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
        for (final s in response.shopfronts.where((e) => e.isEnabled)) s.name: s.id,
      };
      AppGlobals.instance.pairedShopfrontIdsByName = idMap;

      final assigned = response.shopfronts.where((e) => e.isAssigned).toList();
      if (assigned.isNotEmpty) {
        await LocalDbDAO.instance.saveShopfrontId(assigned.first.id);
        await LocalDbDAO.instance.saveShopfrontName(assigned.first.name);
      } else if (response.assignedShopfrontId != null &&
          response.assignedShopfrontId!.isNotEmpty) {
        await LocalDbDAO.instance.saveShopfrontId(response.assignedShopfrontId!);
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
