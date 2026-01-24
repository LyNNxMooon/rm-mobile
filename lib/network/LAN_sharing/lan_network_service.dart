import 'dart:typed_data';

import 'package:rmstock_scanner/entities/response/shopfront_response.dart';
import 'package:rmstock_scanner/entities/vos/network_computer_vo.dart';
import 'package:smb_connect/smb_connect.dart';

abstract class LanNetworkService {
  Future<List<NetworkComputerVO>> scanNetwork();

  Future<List<String>> getDirectoryListing({
    required String address,
    required String path,
    required String username,
    required String password,
  });

  Future<void> writeToSelectedFolder({
    required String address,
    required String fullPath,
    required String username,
    required String password,
  });

  Future<bool> isShopfrontsFileExists({
    required String address,
    required String fullPath,
    required String username,
    required String password,
  });

  Future<ShopfrontResponse> getShopfronts({
    required String address,
    required String fullPath,
    required String username,
    required String password,
  });

  Future<void> writeStocktakeDataToSharedFolder({
    required String address,
    required String fullPath,
    required String username,
    required String password,
    required String fileName,
    required String fileContent,
  });

  Future<void> sendStockRequest({
    required String address,
    required String fullPath,
    required String username,
    required String password,
    required String fileName,
    required String fileContent,
    required String mobileID,
  });

  // Future<Uint8List?> fetchLatestStockFile({
  //   required String address,
  //   required String fullPath,
  //   required String username,
  //   required String password,
  //   required String mobileName,
  // });

  Future<SmbFile?> pollForFile({
    required String address,
    required String fullPath,
    required String username,
    required String password,
    required String fileNamePattern,
    required int maxRetries,
  });

  Future<SmbFile?> pollForStocktakeValidationFile({
    required String address,
    required String fullPath,
    required String username,
    required String password,
    required String fileNamePattern,
    required int maxRetries,
  });

  Future<Uint8List> downloadAndDeleteFile({
    required String address,
    required String username,
    required String password,
    required SmbFile fileToDownload,
  });
}
