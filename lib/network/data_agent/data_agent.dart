import 'package:rmstock_scanner/entities/response/connect_shopfront_response.dart';
import 'package:rmstock_scanner/entities/response/backup_list_response.dart';
import 'package:rmstock_scanner/entities/response/discover_response.dart';
import 'package:rmstock_scanner/entities/response/load_backup_response.dart';
import 'package:rmstock_scanner/entities/response/paircode_response.dart';
import 'package:rmstock_scanner/entities/response/pair_response.dart';
import 'package:rmstock_scanner/entities/response/picture_upload_response.dart';
import 'package:rmstock_scanner/entities/response/shopfronts_api_response.dart';
import 'package:rmstock_scanner/entities/response/stock_lookup_api_response.dart';
import 'package:rmstock_scanner/entities/response/stocktake_backup_response.dart';
import 'package:rmstock_scanner/entities/response/stocktake_commit_response.dart';
import 'package:rmstock_scanner/entities/response/stocktake_initcheck_response.dart';
import 'package:rmstock_scanner/entities/response/stock_update_response.dart';
import 'package:rmstock_scanner/entities/response/validate_response.dart';

abstract class DataAgent {
  Future<DiscoverResponse> discoverHost(String ip, int port);

  Future<PaircodeResponse> getPairCodes(String ip, int port);

  Future<PairResponse> pairDevice(
    String ip,
    int port,
    Map<String, dynamic> body,
  );

  Future<ShopfrontsApiResponse> getShopfronts(
    String ip,
    int port,
    String apiKey,
  );

  Future<ConnectShopfrontResponse> connectShopfront(
    String ip,
    int port,
    String shopfrontId,
    String apiKey,
  );

  Future<StockLookupApiResponse> fetchShopfrontStocks(
    String ip,
    int port,
    String shopfrontId,
    String apiKey,
    Map<String, dynamic> body,
  );

  Future<StockUpdateResponse> updateShopfrontStock(
    String ip,
    int port,
    String shopfrontId,
    String apiKey,
    Map<String, dynamic> body,
  );

  Future<PictureUploadResponse> uploadShopfrontPicture(
    String ip,
    int port,
    String shopfrontId,
    int stockId,
    String apiKey,
    List<int> jpgBytes,
  );

  Future<StocktakeInitcheckResponse> stocktakeInitCheck(
    String ip,
    int port,
    String shopfrontId,
    String apiKey,
    Map<String, dynamic> body,
  );

  Future<StocktakeCommitResponse> stocktakeCommit(
    String ip,
    int port,
    String shopfrontId,
    String apiKey,
    Map<String, dynamic> body,
  );

  Future<StocktakeBackupResponse> stocktakeBackup(
    String ip,
    int port,
    String shopfrontId,
    String apiKey,
    Map<String, dynamic> body,
  );

  Future<BackupListResponse> getStocktakeBackupList(
    String ip,
    int port,
    String shopfrontId,
    String apiKey,
  );

  Future<LoadBackupResponse> loadStocktakeBackup(
    String ip,
    int port,
    String shopfrontId,
    String fileName,
    String apiKey,
  );

  Future<ValidateResponse> validate(
    String ip,
    int port,
    String apiKey,
  );
}
