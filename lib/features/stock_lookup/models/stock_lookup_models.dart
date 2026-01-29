import 'dart:io';
import 'dart:typed_data';

import 'package:rmstock_scanner/entities/response/paginated_stock_response.dart';
import 'package:rmstock_scanner/features/stock_lookup/domain/repositories/stock_lookup_repo.dart';
import 'package:rmstock_scanner/network/LAN_sharing/lan_network_service_impl.dart';
import 'package:rmstock_scanner/utils/global_var_utils.dart';

import '../../../entities/vos/filter_criteria.dart';
import '../../../local_db/local_db_dao.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class StockLookupModels implements StockLookupRepo {
  //Data manipulation can be done here (E.g. substituting data for null values returned from API)
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

      final localFile = File(localPath);
      if (await localFile.exists()) {
        // already cached
        return localPath;
      }

      await Directory(cacheDirPath).create(recursive: true);

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
    } on Exception catch (error) {
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
  }) async {
    try {
      if (pictureFileName.isEmpty) return null;

      // Cache to file system
      final dir = await getTemporaryDirectory();
      final String cacheDirPath = p.join(
        dir.path,
        "fullimg_cache",
        shopfrontName,
      );

      final String localPath = p.join(cacheDirPath, pictureFileName);

      final localFile = File(localPath);
      if (await localFile.exists()) {
        return localPath;
      }

      await Directory(cacheDirPath).create(recursive: true);

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
    } on Exception catch (error) {
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
}
