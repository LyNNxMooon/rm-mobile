import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:rmstock_scanner/entities/response/paginated_stock_response.dart';
import 'package:rmstock_scanner/entities/vos/stock_vo.dart';
import 'package:rmstock_scanner/features/stock_lookup/domain/entities/sync_status.dart';
import 'package:rmstock_scanner/features/stock_lookup/domain/repositories/stock_lookup_repo.dart';
import 'package:rmstock_scanner/network/LAN_sharing/lan_network_service_impl.dart';
import 'package:rmstock_scanner/network/data_agent/data_agent_impl.dart';
import 'package:rmstock_scanner/utils/global_var_utils.dart';
import 'package:rmstock_scanner/utils/log_utils.dart';

import '../../../entities/vos/filter_criteria.dart';
import '../../../local_db/local_db_dao.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class StockLookupModels implements StockLookupRepo {
  //Data manipulation can be done here (E.g. substituting data for null values returned from API)
  @override
  Stream<SyncStatus> fetchAndSaveStocks(String ipAddress) async* {
    try {
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
          final Map<String, dynamic> body = {"pageSize": 10000};
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
            final stocks = response.items.map(StockVO.fromApiItem).toList();
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
          final stocks = response.items.map(StockVO.fromApiItem).toList();
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

  @override
  Future<PaginatedStockResult> fetchStocksDynamic({
    required String shopfront,
    required String query,
    required String filterColumn,
    required String sortColumn,
    required bool ascending,
    required int page,
    FilterCriteria? filters,
    int pageSize = 100,
  }) async {
    try {
      final int offset = (page - 1) * pageSize;
      return LocalDbDAO.instance.searchAndSortStocks(
        shopfront: shopfront,
        query: query,
        filterColumn: filterColumn,
        sortColumn: sortColumn,
        ascending: ascending,
        limit: pageSize,
        offset: offset,
        filters: filters,
      );
    } on Exception catch (error) {
      return Future.error(error);
    }
  }

  @override
  Future<Map<String, List<String>>> getFilterOptions(String shopfront) async {
    try {
      final results = await Future.wait([
        LocalDbDAO.instance.getDistinctValues('dept_name', shopfront),
        LocalDbDAO.instance.getDistinctValues('cat1', shopfront),
        LocalDbDAO.instance.getDistinctValues('cat2', shopfront),
        LocalDbDAO.instance.getDistinctValues('cat3', shopfront),
      ]);

      return {
        'Departments': results[0],
        'Cat1': results[1],
        'Cat2': results[2],
        'Cat3': results[3],
      };
    } on Exception catch (error) {
      return Future.error("Failed to load filters: $error");
    }
  }

  @override
  Future<String?> fetchAndCacheThumbnailPath({
    required String address,
    required String fullPath,
    required String? username,
    required String? password,
    required String shopfrontName,
    required String pictureFileName,
    bool forceRefresh = false,
  }) async {
    try {
      if (pictureFileName.isEmpty) return null;

      final String thumbFileName = _toThumbName(pictureFileName);

      final dir = await getTemporaryDirectory();
      final String cacheDirPath = p.join(
        dir.path,
        "thumb_cache",
        shopfrontName,
      );
      final String localPath = p.join(cacheDirPath, thumbFileName);

      await Directory(cacheDirPath).create(recursive: true);

      final localFile = File(localPath);

      if (forceRefresh && await localFile.exists()) {
        await localFile.delete();
      }

      if (await localFile.exists()) {
        return localPath;
      }

      final Uint8List bytes = await LanNetworkServiceImpl.instance
          .downloadFileBytes(
            address: address,
            fullPath: fullPath,
            username: username ?? AppGlobals.instance.defaultUserName,
            password: password ?? AppGlobals.instance.defaultPwd,
            shopfrontName: shopfrontName,
            thumbFileName: thumbFileName,
          );

      await localFile.writeAsBytes(bytes, flush: true);
      return localPath;
    } catch (error) {
      return Future.error(error);
    }
  }

  String _toThumbName(String pictureFileName) {
    // Replace last extension with .jpg. If no extension, append.
    final int dot = pictureFileName.lastIndexOf('.');
    if (dot <= 0) return "$pictureFileName.jpg";
    return "${pictureFileName.substring(0, dot)}.jpg";
  }

  @override
  Future<String?> fetchAndCacheFullImagePath({
    required String address,
    required String fullPath,
    required String? username,
    required String? password,
    required String shopfrontName,
    required String pictureFileName,
    bool forceRefresh = false,
  }) async {
    try {
      if (pictureFileName.isEmpty) return null;

      final dir = await getTemporaryDirectory();
      final String cacheDirPath = p.join(
        dir.path,
        "fullimg_cache",
        shopfrontName,
      );
      final String localPath = p.join(cacheDirPath, pictureFileName);

      await Directory(cacheDirPath).create(recursive: true);

      final localFile = File(localPath);

      if (forceRefresh && await localFile.exists()) {
        await localFile.delete();
      }

      if (await localFile.exists()) {
        return localPath;
      }

      final Uint8List bytes = await LanNetworkServiceImpl.instance
          .downloadFullImageBytes(
            address: address,
            fullPath: fullPath,
            username: username ?? AppGlobals.instance.defaultUserName,
            password: password ?? AppGlobals.instance.defaultPwd,
            shopfrontName: shopfrontName,
            pictureFileName: pictureFileName,
          );

      await localFile.writeAsBytes(bytes, flush: true);

      return localPath;
    } catch (error) {
      return Future.error(error);
    }
  }

  @override
  Future<void> uploadStockImage({
    required String address,
    required String fullPath,
    required String? username,
    required String? password,
    required String fileName,
    required Uint8List jpgBytes,
  }) async {
    try {
      await LanNetworkServiceImpl.instance.uploadStockImageToIncoming(
        address: address,
        fullPath: fullPath,
        username: username ?? AppGlobals.instance.defaultUserName,
        password: password ?? AppGlobals.instance.defaultPwd,
        fileName: fileName,
        jpgBytes: jpgBytes,
        deleteSamePrefixFirst: true,
      );
    } on Exception catch (e) {
      return Future.error(e);
    }
  }

  @override
  Future sendSingleStockUpdate({
    required String address,
    required String fullPath,
    required String? username,
    required String? password,
    required String mobileName,
    required String mobileID,
    required String shopfrontName,
    required int stockId,
    required String description,
    required double sell,
  }) async {
    try {
      final String jsonContent = _StockUpdateJsonBuilder.buildJson(
        mobileId: mobileID,
        mobileName: mobileName,
        shopfrontName: shopfrontName,
        stockId: stockId,
        description: description,
        sell: sell,
      );

      final now = DateTime.now();
      String pad(int v) => v.toString().padLeft(2, '0');

      final String timestamp =
          "${now.year}"
          "${pad(now.month)}"
          "${pad(now.day)}"
          "${pad(now.hour)}"
          "${pad(now.minute)}"
          "${pad(now.second)}";

      final String fileName =
          "${mobileID}_stockUpdate_$timestamp.json.gz";

      logger.d(address);

      return LanNetworkServiceImpl.instance.writeStocktakeDataToSharedFolder(
        address: address,
        fullPath: fullPath,
        username: username ?? AppGlobals.instance.defaultUserName,
        password: password ?? AppGlobals.instance.defaultPwd,
        fileName: fileName,
        fileContent: jsonContent,
        isCheck: true,
        isBackup: false,
      );
    } on Exception catch (error) {
      return Future.error(error);
    }
  }
}

class _StockUpdateJsonBuilder {
  static String buildJson({
    required String mobileId,
    required String mobileName,
    required String shopfrontName,
    required int stockId,
    required String description,
    required double sell,
  }) {
    final now = DateTime.now().toIso8601String();

    final Map<String, dynamic> finalMap = {
      "mobile_device_id": mobileId,
      "mobile_device_name": mobileName,
      "shopfront": shopfrontName,
      "total_stocks": 1,
      "date_started": now,
      "date_ended": now,
      "data": [
        {
          "stock_id": stockId,
          "description": description,
          "sell": sell,
          "date_modified": now,
        }
      ],
    };

    return const JsonEncoder.withIndent('  ').convert(finalMap);
  }
}
