import 'dart:convert';

import 'package:rmstock_scanner/entities/response/discover_response.dart';
import 'package:rmstock_scanner/entities/response/connect_shopfront_response.dart';
import 'package:rmstock_scanner/entities/response/paircode_response.dart';
import 'package:rmstock_scanner/entities/response/pair_response.dart';
import 'package:rmstock_scanner/entities/response/shopfront_response.dart';
import 'package:rmstock_scanner/entities/vos/network_computer_vo.dart';
import 'package:rmstock_scanner/entities/vos/stock_vo.dart';
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
  Stream<SyncStatus> fetchAndSaveStocks(
    String ipAddress,
    String fullPath,
    String? username,
    String? password,
    String mobileID,
    String shopfront,
  ) async* {
    try {
      // Old setup disabled: shared-folder request/response with .json.gz parts.
      // New setup: direct API POST /api/shopfronts/{shopfrontId}/stock.
      yield SyncStatus(0, 1, "Preparing stock sync...");

      final String savedIp = (await LocalDbDAO.instance.getHostIpAddress() ?? "")
          .trim();
      final String resolvedIp = savedIp.isNotEmpty ? savedIp : ipAddress.trim();

      final int resolvedPort =
          int.tryParse((await LocalDbDAO.instance.getHostPort() ?? "").trim()) ??
          5000;
      final String resolvedApiKey =
          (await LocalDbDAO.instance.getApiKey() ?? "").trim();
      final String resolvedShopfrontId =
          (await LocalDbDAO.instance.getShopfrontId() ?? "").trim();
      final String resolvedShopfrontName =
          (await LocalDbDAO.instance.getShopfrontName() ?? "").trim();

      if (resolvedIp.isEmpty ||
          resolvedApiKey.isEmpty ||
          resolvedShopfrontId.isEmpty ||
          resolvedShopfrontName.isEmpty) {
        throw Exception(
          "Missing host/shopfront setup. Please reconnect to a host and shopfront.",
        );
      }

      AppGlobals.instance.currentHostIp = resolvedIp;
      AppGlobals.instance.shopfront = resolvedShopfrontName;

      final String syncKey = "stock_sync_timestamp_$resolvedShopfrontId";
      final String? lastSyncTimestamp = await LocalDbDAO.instance.getAppConfig(
        syncKey,
      );
      final bool isFullSync =
          lastSyncTimestamp == null || lastSyncTimestamp.isEmpty;

      String latestSyncTimestamp = DateTime.now().toIso8601String();

      if (isFullSync) {
        yield SyncStatus(0, 1, "Starting full sync...");

        await LocalDbDAO.instance.clearStocksForShop(resolvedShopfrontName);

        int processed = 0;
        int total = 1;
        int? afterStockId;
        bool hasMore = true;

        while (hasMore) {
          final Map<String, dynamic> body = {"pageSize": 5000};
          if (afterStockId != null && afterStockId > 0) {
            body["afterStockId"] = afterStockId;
          }

          final response = await DataAgentImpl.instance.fetchShopfrontStocks(
            resolvedIp,
            resolvedPort,
            resolvedShopfrontId,
            resolvedApiKey,
            body,
          );

          if (!response.success) {
            throw Exception(response.message);
          }

          latestSyncTimestamp = response.syncTimestamp;
          total = response.totalItems > 0 ? response.totalItems : total;

          if (response.items.isNotEmpty) {
            final stocks = response.items.map(_toStockFromApiItem).toList();
            await LocalDbDAO.instance.insertStocks(stocks, resolvedShopfrontName);
            processed += stocks.length;
          }

          yield SyncStatus(
            processed,
            total,
            "Syncing stocks... ($processed/$total)",
          );

          hasMore = response.hasMore;
          afterStockId = response.lastStockId;

          if (hasMore && (afterStockId == null || afterStockId <= 0)) {
            hasMore = false;
          }
        }
      } else {
        yield SyncStatus(0, 1, "Checking for stock updates...");

        final response = await DataAgentImpl.instance.fetchShopfrontStocks(
          resolvedIp,
          resolvedPort,
          resolvedShopfrontId,
          resolvedApiKey,
          {"lastSyncTimestamp": lastSyncTimestamp},
        );

        if (!response.success) {
          throw Exception(response.message);
        }

        latestSyncTimestamp = response.syncTimestamp;

        if (response.items.isNotEmpty) {
          final stocks = response.items.map(_toStockFromApiItem).toList();
          await LocalDbDAO.instance.insertStocks(stocks, resolvedShopfrontName);
        }

        final int deltaCount = response.itemCount;
        yield SyncStatus(
          deltaCount,
          deltaCount == 0 ? 1 : deltaCount,
          deltaCount == 0
              ? "No stock changes found."
              : "Applied $deltaCount stock updates.",
        );
      }

      await LocalDbDAO.instance.saveAppConfig(syncKey, latestSyncTimestamp);
      yield SyncStatus(1, 1, "Stock sync completed.");
    } on Exception catch (error) {
      yield* Stream.error(error);
    }
  }

  StockVO _toStockFromApiItem(Map<String, dynamic> item) {
    final mapped = <String, dynamic>{
      "stock_id": _asNum(item["stock_id"]),
      "Barcode": _asString(item["barcode"] ?? item["Barcode"]),
      "description": _asString(item["description"]),
      "dept_name": _asNullableString(item["dept_name"]),
      "dept_id": _asInt(item["dept_id"]),
      "custom1": _asNullableString(item["custom1"]),
      "custom2": _asNullableString(item["custom2"]),
      "longdesc": _asNullableString(item["longdesc"]),
      "supplier": _asString(item["supplier"]),
      "cat1": _asNullableString(item["cat1"]),
      "cat2": _asNullableString(item["cat2"]),
      "cat3": _asNullableString(item["cat3"]),
      "cost": _asNum(item["cost"]),
      "sell": _asNum(item["sell"]),
      "inactive": _asBool(item["inactive"]),
      "quantity": _asNum(item["quantity"]),
      "layby_qty": _asNum(item["layby_qty"]),
      "salesorder_qty": _asNum(item["salesorder_qty"]),
      "date_created": _asString(item["date_created"]),
      "order_threshold": _asNum(item["order_threshold"]),
      "order_quantity": _asNum(item["order_quantity"]),
      "allow_fractions": _asBool(item["allow_fractions"]),
      "package": _asBool(item["package"]),
      "static_quantity": _asBool(item["static_quantity"]),
      "picture_file_name": _asNullableString(item["picture_file_name"]),
      "imageUrl": _asNullableString(
        item["picture_url"] ?? item["thumbnail_url"] ?? item["imageUrl"],
      ),
      "goods_tax": _asNullableString(item["goods_tax"]),
      "sales_tax": _asNullableString(item["sales_tax"]),
      "date_modified": _asString(item["date_modified"]),
      "freight": _asBool(item["freight"]),
      "tare_weight": _asNum(item["tare_weight"]),
      "unitof_measure": _asNum(item["unit_of_measure"] ?? item["unitof_measure"]),
      "weighted": _asBool(item["weighted"]),
      "track_serial": _asBool(item["track_serial"]),
    };

    return StockVO.fromJsonNetwork(mapped);
  }

  String _asString(dynamic value) {
    return value == null ? "" : value.toString();
  }

  String? _asNullableString(dynamic value) {
    if (value == null) return null;
    final parsed = value.toString();
    return parsed.isEmpty ? null : parsed;
  }

  int? _asInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  num _asNum(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value;
    final parsed = num.tryParse(value.toString());
    return parsed ?? 0;
  }

  bool _asBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final lower = value.toLowerCase();
      return lower == "true" || lower == "1";
    }
    return false;
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

class SyncStatus {
  final int processed;
  final int total;
  final String message;

  SyncStatus(this.processed, this.total, this.message);
}
