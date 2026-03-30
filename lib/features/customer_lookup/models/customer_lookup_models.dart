import 'package:rmstock_scanner/entities/response/paginated_customer_response.dart';
import 'package:rmstock_scanner/entities/response/staff_detail_response.dart';
import 'package:rmstock_scanner/entities/response/customer_update_response.dart';
import 'package:rmstock_scanner/entities/response/customer_create_response.dart';
import 'package:rmstock_scanner/entities/vos/customer_vo.dart';
import 'package:rmstock_scanner/entities/vos/search_mode.dart';
import 'package:rmstock_scanner/features/customer_lookup/domain/entities/customer_sync_status.dart';
import 'package:rmstock_scanner/features/customer_lookup/domain/entities/customer_transactions_local_data.dart';
import 'package:rmstock_scanner/features/customer_lookup/domain/repositories/customer_lookup_repo.dart';
import 'package:rmstock_scanner/network/data_agent/data_agent_impl.dart';
import 'package:rmstock_scanner/utils/global_var_utils.dart';

import '../../../entities/vos/filter_criteria.dart';
import '../../../local_db/local_db_dao.dart';
import '../../../local_db/sqlite/sqlite_constants.dart';

class CustomerLookupModels implements CustomerLookupRepo {
  @override
  Stream<CustomerSyncStatus> fetchAndSaveCustomers(String ipAddress) async* {
    try {
      yield CustomerSyncStatus(0, 1, "Preparing customer sync...");

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

      final String syncKey = "customer_sync_timestamp_$resolvedShopfrontId";
      final String? lastSyncTimestamp = await LocalDbDAO.instance.getAppConfig(
        syncKey,
      );
      final bool isFullSync =
          lastSyncTimestamp == null || lastSyncTimestamp.isEmpty;

      String latestSyncTimestamp =
          (lastSyncTimestamp != null && lastSyncTimestamp.trim().isNotEmpty)
              ? lastSyncTimestamp
              : DateTime.now().toIso8601String();

      String resolveSyncTimestamp(String value, String fallback) {
        return value.trim().isNotEmpty ? value : fallback;
      }

      if (isFullSync) {
        yield CustomerSyncStatus(0, 1, "Starting full sync...");

        await LocalDbDAO.instance.clearCustomersForShop(resolvedShopfrontName);

        int processed = 0;
        int total = 1;
        int? afterCustomerId;
        bool hasMore = true;
        int maxRemoteCustomerId = 0;

        while (hasMore) {
          final Map<String, dynamic> body = {"pageSize": 10000};
          if (afterCustomerId != null && afterCustomerId > 0) {
            body["afterCustomerId"] = afterCustomerId;
          }

          final response = await DataAgentImpl.instance.fetchShopfrontCustomers(
            resolvedIp,
            resolvedPort,
            resolvedShopfrontId,
            resolvedApiKey,
            body,
          );

          if (!response.success) {
            throw Exception(response.message);
          }

          AppGlobals.instance.updateCustomLabels(
            stock1: response.stock1,
            stock2: response.stock2,
            customer1: response.customer1,
            customer2: response.customer2,
            customer3: response.customer3,
          );

          latestSyncTimestamp = resolveSyncTimestamp(
            response.syncTimestamp,
            latestSyncTimestamp,
          );
          if (response.lastCustomerId != null &&
              response.lastCustomerId! > maxRemoteCustomerId) {
            maxRemoteCustomerId = response.lastCustomerId!;
          }
          total = response.totalItems > 0 ? response.totalItems : total;

          if (response.items.isNotEmpty) {
            final customers = response.items.map(CustomerVO.fromApiItem).toList();
            await LocalDbDAO.instance.insertCustomers(customers, resolvedShopfrontName);
            processed += customers.length;
          }

          yield CustomerSyncStatus(
            processed,
            total,
            "Syncing customers... ($processed/$total)",
          );

          hasMore = response.hasMore;
          afterCustomerId = response.lastCustomerId;

          if (hasMore && (afterCustomerId == null || afterCustomerId <= 0)) {
            hasMore = false;
          }
        }

        if (maxRemoteCustomerId > 0) {
          await LocalDbDAO.instance.saveAppConfig(
            '$kCustomerMaxIdPrefix$resolvedShopfrontName',
            maxRemoteCustomerId.toString(),
          );
        }
      } else {
        yield CustomerSyncStatus(0, 1, "Checking for customer updates...");

        final response = await DataAgentImpl.instance.fetchShopfrontCustomers(
          resolvedIp,
          resolvedPort,
          resolvedShopfrontId,
          resolvedApiKey,
          {"lastSyncTimestamp": lastSyncTimestamp},
        );

        if (!response.success) {
          throw Exception(response.message);
        }

        AppGlobals.instance.updateCustomLabels(
          stock1: response.stock1,
          stock2: response.stock2,
          customer1: response.customer1,
          customer2: response.customer2,
          customer3: response.customer3,
        );

        latestSyncTimestamp = resolveSyncTimestamp(
          response.syncTimestamp,
          latestSyncTimestamp,
        );

        if (response.lastCustomerId != null && response.lastCustomerId! > 0) {
          await LocalDbDAO.instance.saveAppConfig(
            '$kCustomerMaxIdPrefix$resolvedShopfrontName',
            response.lastCustomerId.toString(),
          );
        }

        if (response.items.isNotEmpty) {
          final customers = response.items.map(CustomerVO.fromApiItem).toList();
          await LocalDbDAO.instance.insertCustomers(customers, resolvedShopfrontName);
        }

        final int deltaCount = response.itemCount;
        yield CustomerSyncStatus(
          deltaCount,
          deltaCount == 0 ? 1 : deltaCount,
          deltaCount == 0
              ? "No customer changes found."
              : "Applied $deltaCount customer updates.",
        );
      }

      await LocalDbDAO.instance.renewPendingCustomerCreationIds(
        resolvedShopfrontName,
      );
      await LocalDbDAO.instance.saveAppConfig(syncKey, latestSyncTimestamp);
      yield CustomerSyncStatus(1, 1, "Customer sync completed.");
    } on Exception catch (error) {
      yield* Stream.error(error);
    }
  }

  @override
  Future<PaginatedCustomerResult> fetchCustomersDynamic({
    required String shopfront,
    required String query,
    required String filterColumn,
    required String sortColumn,
    required bool ascending,
    required int page,
    FilterCriteria? filters,
    int pageSize = 100,
    SearchMode searchMode = SearchMode.partial,
  }) async {
    try {
      final int offset = (page - 1) * pageSize;
      return LocalDbDAO.instance.searchAndSortCustomers(
        shopfront: shopfront,
        query: query,
        filterColumn: filterColumn,
        sortColumn: sortColumn,
        ascending: ascending,
        limit: pageSize,
        offset: offset,
        filters: filters,
        searchMode: searchMode,
      );
    } on Exception catch (error) {
      return Future.error(error);
    }
  }

  @override
  Future<Map<String, List<String>>> getFilterOptions(String shopfront) async {
    try {
      final results = await Future.wait([
        LocalDbDAO.instance.getDistinctCustomerValues('state', shopfront),
        LocalDbDAO.instance.getDistinctCustomerValues('suburb', shopfront),
        LocalDbDAO.instance.getDistinctCustomerValues('postcode', shopfront),
      ]);

      return {
        'State': results[0],
        'Suburb': results[1],
        'Postcode': results[2],
      };
    } on Exception catch (error) {
      return Future.error("Failed to load filters: $error");
    }
  }

  @override
  Future<StaffDetailResponse> fetchStaffDetail(int staffId) async {
    try {
      if (staffId <= 0) {
        return Future.error("Invalid staff id: $staffId");
      }

      final String resolvedIp =
          (await LocalDbDAO.instance.getHostIpAddress() ?? "").trim();
      final int resolvedPort =
          int.tryParse((await LocalDbDAO.instance.getHostPort() ?? "").trim()) ??
          5000;
      final String resolvedApiKey =
          (await LocalDbDAO.instance.getApiKey() ?? "").trim();
      final String resolvedShopfrontId =
          (await LocalDbDAO.instance.getShopfrontId() ?? "").trim();

      if (resolvedIp.isEmpty ||
          resolvedApiKey.isEmpty ||
          resolvedShopfrontId.isEmpty) {
        throw Exception(
          "Missing host/shopfront setup. Please reconnect to a host and shopfront.",
        );
      }

      return await DataAgentImpl.instance.getStaffDetail(
        resolvedIp,
        resolvedPort,
        resolvedShopfrontId,
        resolvedApiKey,
        staffId,
      );
    } on Exception catch (error) {
      return Future.error(error);
    }
  }

  @override
  Future<StaffDetailResponse> fetchStaffByBarcode(String staffBarcode) async {
    try {
      final String trimmed = staffBarcode.trim();
      if (trimmed.isEmpty) {
        return Future.error("Invalid staff barcode: $staffBarcode");
      }

      final String resolvedIp =
          (await LocalDbDAO.instance.getHostIpAddress() ?? "").trim();
      final int resolvedPort =
          int.tryParse((await LocalDbDAO.instance.getHostPort() ?? "").trim()) ??
          5000;
      final String resolvedApiKey =
          (await LocalDbDAO.instance.getApiKey() ?? "").trim();
      final String resolvedShopfrontId =
          (await LocalDbDAO.instance.getShopfrontId() ?? "").trim();

      if (resolvedIp.isEmpty ||
          resolvedApiKey.isEmpty ||
          resolvedShopfrontId.isEmpty) {
        throw Exception(
          "Missing host/shopfront setup. Please reconnect to a host and shopfront.",
        );
      }

      return await DataAgentImpl.instance.getStaffByBarcode(
        resolvedIp,
        resolvedPort,
        resolvedShopfrontId,
        resolvedApiKey,
        trimmed,
      );
    } on Exception catch (error) {
      return Future.error(error);
    }
  }

  @override
  Future<CustomerUpdateResponse> updateCustomerDetails(
    Map<String, dynamic> body,
  ) async {
    try {
      final String resolvedIp =
          (await LocalDbDAO.instance.getHostIpAddress() ?? "").trim();
      final int resolvedPort =
          int.tryParse((await LocalDbDAO.instance.getHostPort() ?? "").trim()) ??
          5000;
      final String resolvedApiKey =
          (await LocalDbDAO.instance.getApiKey() ?? "").trim();
      final String resolvedShopfrontId =
          (await LocalDbDAO.instance.getShopfrontId() ?? "").trim();

      if (resolvedIp.isEmpty ||
          resolvedApiKey.isEmpty ||
          resolvedShopfrontId.isEmpty) {
        throw Exception(
          "Missing host/shopfront setup. Please reconnect to a host and shopfront.",
        );
      }

      return await DataAgentImpl.instance.updateShopfrontCustomers(
        resolvedIp,
        resolvedPort,
        resolvedShopfrontId,
        resolvedApiKey,
        body,
      );
    } on Exception catch (error) {
      return Future.error(error);
    }
  }

  @override
  Future<CustomerCreateResponse> createCustomer(
    Map<String, dynamic> body,
  ) async {
    try {
      final String resolvedIp =
          (await LocalDbDAO.instance.getHostIpAddress() ?? "").trim();
      final int resolvedPort =
          int.tryParse((await LocalDbDAO.instance.getHostPort() ?? "").trim()) ??
          5000;
      final String resolvedApiKey =
          (await LocalDbDAO.instance.getApiKey() ?? "").trim();
      final String resolvedShopfrontId =
          (await LocalDbDAO.instance.getShopfrontId() ?? "").trim();

      if (resolvedIp.isEmpty ||
          resolvedApiKey.isEmpty ||
          resolvedShopfrontId.isEmpty) {
        throw Exception(
          "Missing host/shopfront setup. Please reconnect to a host and shopfront.",
        );
      }

      return await DataAgentImpl.instance.createShopfrontCustomers(
        resolvedIp,
        resolvedPort,
        resolvedShopfrontId,
        resolvedApiKey,
        body,
      );
    } on Exception catch (error) {
      return Future.error(error);
    }
  }

  @override
  Future<void> fetchAndSaveCustomerTransactions({required int customerId}) async {
    try {
      if (customerId <= 0) {
        return Future.error("Invalid customer id: $customerId");
      }

      final String resolvedIp =
          (await LocalDbDAO.instance.getHostIpAddress() ?? "").trim();
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

      final response = await DataAgentImpl.instance.fetchCustomerTransactions(
        resolvedIp,
        resolvedPort,
        resolvedShopfrontId,
        customerId,
        resolvedApiKey,
      );

      if (!response.success) {
        return Future.error(response.message);
      }

      await LocalDbDAO.instance.replaceCustomerTransactions(
        shopfront: resolvedShopfrontName,
        customerId: customerId,
        purchases: response.data.purchases
            .map(
              (item) => {
                "customer_id": customerId,
                "shopfront": resolvedShopfrontName,
                "date": item.date,
                "product": item.product,
                "qty": item.qty,
                "price": item.price,
                "price_inc": item.priceInc,
                "stock_id": item.stockId,
                "goods_tax": item.goodsTax,
              },
            )
            .toList(),
        credit: response.data.credit
            .map(
              (item) => {
                "customer_id": customerId,
                "shopfront": resolvedShopfrontName,
                "date": item.date,
                "credit_id": item.creditId,
                "source": item.source,
                "credit_type": item.creditType,
                "amount": item.amount,
              },
            )
            .toList(),
        invoices: response.data.invoices
            .map(
              (item) => {
                "customer_id": customerId,
                "shopfront": resolvedShopfrontName,
                "date": item.date,
                "invoice_no": item.invoiceNo,
                "inv_total": item.invTotal,
                "amount_owing": item.amountOwing,
              },
            )
            .toList(),
        ivPay: response.data.ivPay
            .map(
              (item) => {
                "customer_id": customerId,
                "shopfront": resolvedShopfrontName,
                "date": item.date,
                "invoice_no": item.invoiceNo,
                "payment_no": item.paymentNo,
                "trn": item.trn,
                "discount": item.discount,
                "amount_paid": item.amountPaid,
              },
            )
            .toList(),
        laybys: response.data.laybys
            .map(
              (item) => {
                "customer_id": customerId,
                "shopfront": resolvedShopfrontName,
                "date": item.date,
                "layby_no": item.laybyNo,
                "last_payment": item.lastPayment,
                "total": item.total,
                "amount_owing": item.amountOwing,
              },
            )
            .toList(),
        lbPay: response.data.lbPay
            .map(
              (item) => {
                "customer_id": customerId,
                "shopfront": resolvedShopfrontName,
                "date": item.date,
                "layby_no": item.laybyNo,
                "payment_no": item.paymentNo,
                "amount_paid": item.amountPaid,
                "payment_type": item.paymentType,
              },
            )
            .toList(),
        cso: response.data.cso
            .map(
              (item) => {
                "customer_id": customerId,
                "shopfront": resolvedShopfrontName,
                "date": item.date,
                "product": item.product,
                "sell": item.sell,
                "qty": item.qty,
                "status": item.status,
              },
            )
            .toList(),
        soQuote: response.data.soQuote
            .map(
              (item) => {
                "customer_id": customerId,
                "shopfront": resolvedShopfrontName,
                "date": item.date,
                "sales_order_no": item.salesOrderNo,
                "type": item.type,
                "status": item.status,
                "total": item.total,
                "owing": item.owing,
              },
            )
            .toList(),
        soPay: response.data.soPay
            .map(
              (item) => {
                "customer_id": customerId,
                "shopfront": resolvedShopfrontName,
                "date": item.date,
                "sales_order_no": item.salesOrderNo,
                "payment_no": item.paymentNo,
                "amount_paid": item.amountPaid,
                "payment_type": item.paymentType,
              },
            )
            .toList(),
      );
    } on Exception catch (error) {
      return Future.error(error);
    }
  }

  @override
  Future<CustomerTransactionsLocalData> getCustomerTransactionsLocal({
    required int customerId,
  }) async {
    if (customerId <= 0) {
      return Future.error("Invalid customer id: $customerId");
    }

    final String appShopfront = (AppGlobals.instance.shopfront ?? "").trim();
    final String resolvedShopfront = appShopfront.isNotEmpty
        ? appShopfront
        : (await LocalDbDAO.instance.getShopfrontName() ?? "").trim();

    if (resolvedShopfront.isEmpty) {
      return CustomerTransactionsLocalData.empty();
    }

    final results = await Future.wait([
      LocalDbDAO.instance.getCustomerPurchases(
        shopfront: resolvedShopfront,
        customerId: customerId,
        limit: 20,
      ),
      LocalDbDAO.instance.getCustomerCredit(
        shopfront: resolvedShopfront,
        customerId: customerId,
        limit: 10,
      ),
      LocalDbDAO.instance.getCustomerInvoices(
        shopfront: resolvedShopfront,
        customerId: customerId,
        limit: 10,
      ),
      LocalDbDAO.instance.getCustomerIvPay(
        shopfront: resolvedShopfront,
        customerId: customerId,
        limit: 10,
      ),
      LocalDbDAO.instance.getCustomerLaybys(
        shopfront: resolvedShopfront,
        customerId: customerId,
        limit: 10,
      ),
      LocalDbDAO.instance.getCustomerLbPay(
        shopfront: resolvedShopfront,
        customerId: customerId,
        limit: 10,
      ),
      LocalDbDAO.instance.getCustomerCso(
        shopfront: resolvedShopfront,
        customerId: customerId,
        limit: 10,
      ),
      LocalDbDAO.instance.getCustomerSoQuote(
        shopfront: resolvedShopfront,
        customerId: customerId,
        limit: 10,
      ),
      LocalDbDAO.instance.getCustomerSoPay(
        shopfront: resolvedShopfront,
        customerId: customerId,
        limit: 10,
      ),
    ]);

    return CustomerTransactionsLocalData(
      purchases: results[0],
      credit: results[1],
      invoices: results[2],
      ivPay: results[3],
      laybys: results[4],
      lbPay: results[5],
      cso: results[6],
      soQuote: results[7],
      soPay: results[8],
    );
  }

  @override
  Future<bool> checkBarcodeExists({
    required String shopfront,
    required String barcode,
  }) async {
    try {
      return LocalDbDAO.instance.checkBarcodeExists(barcode, shopfront);
    } on Exception catch (error) {
      return Future.error(error);
    }
  }

  @override
  Future<String> getNextNumericBarcode({required String shopfront}) async {
    try {
      return LocalDbDAO.instance.getNextNumericBarcode(shopfront);
    } on Exception catch (error) {
      return Future.error(error);
    }
  }

  @override
  Future<int> getNextCustomerId({required String shopfront}) async {
    try {
      return LocalDbDAO.instance.getNextCustomerId(shopfront);
    } on Exception catch (error) {
      return Future.error(error);
    }
  }

  @override
  Future<int> getNextCustomerAddressId({required String shopfront}) async {
    try {
      return LocalDbDAO.instance.getNextCustomerAddressId(shopfront);
    } on Exception catch (error) {
      return Future.error(error);
    }
  }

  @override
  Future<String?> getHostIpAddress() async {
    try {
      return LocalDbDAO.instance.getHostIpAddress();
    } on Exception catch (error) {
      return Future.error(error);
    }
  }

  @override
  Future<String?> getShopfrontName() async {
    try {
      final fromGlobals = (AppGlobals.instance.shopfront ?? "").trim();
      if (fromGlobals.isNotEmpty) return fromGlobals;
      return (await LocalDbDAO.instance.getShopfrontName())?.trim();
    } on Exception catch (error) {
      return Future.error(error);
    }
  }
}
