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
    required bool isCheck,
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

  Future<Uint8List> downloadFileBytes({
    required String address,
    required String fullPath,
    required String username,
    required String password,
    required String shopfrontName,
    required String thumbFileName,
  });

  Future<Uint8List> downloadFullImageBytes({
    required String address,
    required String fullPath,
    required String username,
    required String password,
    required String shopfrontName,
    required String pictureFileName,
  });

  Future<void> uploadStockImageToIncoming({
    required String address,
    required String fullPath,
    required String username,
    required String password,
    required String fileName, // must end with .jpg
    required Uint8List jpgBytes,
    bool deleteSamePrefixFirst = true,
  });
}
