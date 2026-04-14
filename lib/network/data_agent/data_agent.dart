import 'package:rmmobile/entities/response/connect_shopfront_response.dart';
import 'package:rmmobile/entities/response/authenticate_staff_response.dart';
import 'package:rmmobile/entities/response/backup_list_response.dart';
import 'package:rmmobile/entities/response/discover_response.dart';
import 'package:rmmobile/entities/response/load_backup_response.dart';
import 'package:rmmobile/entities/response/paircode_response.dart';
import 'package:rmmobile/entities/response/pair_response.dart';
import 'package:rmmobile/entities/response/picture_upload_response.dart';
import 'package:rmmobile/entities/response/shopfronts_api_response.dart';
import 'package:rmmobile/entities/response/stock_lookup_api_response.dart';
import 'package:rmmobile/entities/response/customer_lookup_api_response.dart';
import 'package:rmmobile/entities/response/customer_update_response.dart';
import 'package:rmmobile/entities/response/customer_create_response.dart';
import 'package:rmmobile/entities/response/customer_transactions_response.dart';
import 'package:rmmobile/entities/response/invoice_response.dart';
import 'package:rmmobile/entities/response/stocktake_backup_response.dart';
import 'package:rmmobile/entities/response/stocktake_commit_response.dart';
import 'package:rmmobile/entities/response/stocktake_initcheck_response.dart';
import 'package:rmmobile/entities/response/stocktake_limit_response.dart';
import 'package:rmmobile/entities/response/stock_update_response.dart';
import 'package:rmmobile/entities/response/validate_response.dart';
import 'package:rmmobile/entities/response/security_groups_response.dart';
import 'package:rmmobile/entities/response/staff_detail_response.dart';

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

  Future<CustomerLookupApiResponse> fetchShopfrontCustomers(
    String ip,
    int port,
    String shopfrontId,
    String apiKey,
    Map<String, dynamic> body,
  );

  Future<CustomerUpdateResponse> updateShopfrontCustomers(
    String ip,
    int port,
    String shopfrontId,
    String apiKey,
    Map<String, dynamic> body,
  );

  Future<CustomerCreateResponse> createShopfrontCustomers(
    String ip,
    int port,
    String shopfrontId,
    String apiKey,
    Map<String, dynamic> body,
  );

  Future<CustomerTransactionsResponse> fetchCustomerTransactions(
    String ip,
    int port,
    String shopfrontId,
    int customerId,
    String apiKey,
  );

  Future<InvoiceResponse> createInvoice(
    String ip,
    int port,
    String shopfrontId,
    String apiKey,
    Map<String, dynamic> body,
  );

  Future<InvoiceResponse> createSalesOrder(
    String ip,
    int port,
    String shopfrontId,
    String apiKey,
    Map<String, dynamic> body,
  );

  Future<InvoiceResponse> createQuote(
    String ip,
    int port,
    String shopfrontId,
    String apiKey,
    Map<String, dynamic> body,
  );

  Future<InvoiceResponse> createLayby(
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

  Future<AuthenticateStaffResponse> authenticateStaff(
    String ip,
    int port,
    String shopfrontId,
    String apiKey,
    Map<String, dynamic> body,
  );

  Future<SecurityGroupsResponse> getSecurityGroups(
    String ip,
    int port,
    String shopfrontId,
    String apiKey,
  );

  Future<StaffDetailResponse> getStaffDetail(
    String ip,
    int port,
    String shopfrontId,
    String apiKey,
    int staffId,
  );

  Future<StaffDetailResponse> getStaffByBarcode(
    String ip,
    int port,
    String shopfrontId,
    String apiKey,
    String staffBarcode,
  );

  Future<StocktakeLimitResponse> getStocktakeLimit(
    String ip,
    int port,
    String apiKey,
  );

  Future<ValidateResponse> validate(String ip, int port, String apiKey);
}
