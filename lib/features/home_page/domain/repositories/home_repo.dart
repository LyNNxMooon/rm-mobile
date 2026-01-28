import 'package:rmstock_scanner/entities/response/shopfront_response.dart';

import '../../../../entities/vos/network_computer_vo.dart';
import '../../models/home_screen_models.dart';

abstract class HomeRepo {
  Future<List<NetworkComputerVO>> fetchNetworkPCs();
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

  Stream<SyncStatus> fetchAndSaveStocks(
    String ipAddress,
    String fullPath,
    String? username,
    String? password,
    String mobileName,
    String shopfront,
  );

  Future<int> getRetentionDays();

  Future<void> setRetentionDays(int days);

  Future<int> runHistoryCleanup();
}
