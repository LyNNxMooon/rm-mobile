import 'package:rmmobile/entities/response/paginated_customer_response.dart';
import 'package:rmmobile/entities/response/staff_detail_response.dart';
import 'package:rmmobile/entities/response/customer_update_response.dart';
import 'package:rmmobile/entities/response/customer_create_response.dart';
import 'package:rmmobile/entities/response/customer_balance_response.dart';
import 'package:rmmobile/entities/vos/customer_vo.dart';
import 'package:rmmobile/entities/vos/search_mode.dart';
import 'dart:math' as math;
import 'package:rmmobile/entities/vos/sync_metadata.dart';
import 'package:rmmobile/features/customer_lookup/domain/entities/customer_sync_status.dart';
import 'package:rmmobile/features/customer_lookup/domain/entities/customer_transactions_local_data.dart';
import 'package:rmmobile/features/customer_lookup/domain/repositories/customer_lookup_repo.dart';
import 'package:rmmobile/network/data_agent/data_agent_impl.dart';
import 'package:rmmobile/utils/global_var_utils.dart';
import 'package:rmmobile/utils/log_utils.dart';

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

      yield* _reconcileDeletedCustomers(
        ip: resolvedIp,
        port: resolvedPort,
        shopfrontId: resolvedShopfrontId,
        apiKey: resolvedApiKey,
        shopfrontName: resolvedShopfrontName,
      );

      await LocalDbDAO.instance.renewPendingCustomerCreationIds(
        resolvedShopfrontName,
      );
      await LocalDbDAO.instance.saveAppConfig(syncKey, latestSyncTimestamp);
      yield CustomerSyncStatus(1, 1, "Customer sync completed.");
    } on Exception catch (error) {
      yield* Stream.error(error);
    }
  }

  Stream<CustomerSyncStatus> _reconcileDeletedCustomers({
    required String ip,
    required int port,
    required String shopfrontId,
    required String apiKey,
    required String shopfrontName,
  }) async* {
    final localMeta =
        await LocalDbDAO.instance.getCustomerSyncMetadata(shopfrontName);
    final serverMeta = await DataAgentImpl.instance.fetchCustomerMetadata(
      ip,
      port,
      shopfrontId,
      apiKey,
    );
    final serverSnapshot = SyncMetadata(
      count: serverMeta.metadata.count,
      minId: serverMeta.metadata.minCustomerId,
      maxId: serverMeta.metadata.maxCustomerId,
      checksum: serverMeta.metadata.idChecksum,
    );

    if (localMeta.matches(serverSnapshot)) {
      return;
    }

    if (localMeta.count == 0) {
      return;
    }

    final int startId = localMeta.minId;
    final int endId = localMeta.maxId;
    if (endId < startId) return;

    const int chunkSize = 10000;
    final int totalChunks = ((endId - startId) ~/ chunkSize) + 1;

    for (int chunkIndex = 0; chunkIndex < totalChunks; chunkIndex++) {
      final int fromId = startId + (chunkIndex * chunkSize);
      final int toId = math.min(fromId + chunkSize - 1, endId);

      yield CustomerSyncStatus(
        chunkIndex + 1,
        totalChunks,
        "Reconciling deleted customers... (${chunkIndex + 1}/$totalChunks)",
      );

      final response = await DataAgentImpl.instance.fetchCustomerIds(
        ip,
        port,
        shopfrontId,
        apiKey,
        {
          'fromCustomerId': fromId,
          'toCustomerId': toId,
        },
      );

      final localIds = await LocalDbDAO.instance.getCustomerIdsInRange(
        shopfront: shopfrontName,
        fromId: fromId,
        toId: toId,
      );

      if (localIds.isEmpty) continue;

      final serverIds = response.customerIds.toSet();
      final missing =
          localIds.where((id) => !serverIds.contains(id)).toList();

      if (missing.isNotEmpty) {
        await LocalDbDAO.instance.deleteCustomersByIds(
          shopfront: shopfrontName,
          customerIds: missing,
        );
      }
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
  Future<CustomerBalanceResponse> fetchCustomerBalance({
    required int customerId,
  }) async {
    if (customerId <= 0) {
      return Future.error("Invalid customer id: $customerId");
    }

    final String resolvedShopfrontName =
        (await LocalDbDAO.instance.getShopfrontName() ?? "").trim();

    // 1) Try to fetch the latest balance from the API and store it locally.
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

      final response = await DataAgentImpl.instance.fetchCustomerBalance(
        resolvedIp,
        resolvedPort,
        resolvedShopfrontId,
        customerId,
        resolvedApiKey,
      );

      // Store the freshly fetched balance for offline use.
      if (resolvedShopfrontName.isNotEmpty) {
        await LocalDbDAO.instance.upsertCustomerBalance(
          customerId: customerId,
          shopfront: resolvedShopfrontName,
          owingAmount: response.owingAmount,
          creditLimit: response.creditLimit,
          remainingCredit: response.remainingCredit,
        );
      } else {
        // No shopfront name to key the local cache; return the fresh response.
        return response;
      }
    } catch (error) {
      // Offline / API failure: fall through and present from local DB.
      logger.e(
        'Error fetching customer balance from network, using local cache: $error',
      );
    }

    // 2) Always present by drawing from the local DB.
    if (resolvedShopfrontName.isNotEmpty) {
      final cached = await LocalDbDAO.instance.getCustomerBalance(
        customerId: customerId,
        shopfront: resolvedShopfrontName,
      );
      if (cached != null) {
        return CustomerBalanceResponse(
          success: true,
          message: null,
          shopfrontId: null,
          customerId: customerId,
          owingAmount: cached.owingAmount,
          creditLimit: cached.creditLimit,
          remainingCredit: cached.remainingCredit,
        );
      }
    }

    return Future.error("Unable to load customer balance.");
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

      // Fetch purchases by default (first tab) with 500 records
      final response = await DataAgentImpl.instance.fetchCustomerTransactions(
        resolvedIp,
        resolvedPort,
        resolvedShopfrontId,
        customerId,
        resolvedApiKey,
        {"transaction_type": "purchase", "page_size": 500},
      );

      logger.d('Fetched transactions for customer $customerId: success=${response.success}, purchases=${response.data.purchases?.length ?? 0}');

      if (!response.success) {
        return Future.error(response.message);
      }

      // Only save purchases since that's what we fetched
      await LocalDbDAO.instance.replaceCustomerTransactionsByType(
        shopfront: resolvedShopfrontName,
        customerId: customerId,
        transactionType: 'purchase',
        transactions: (response.data.purchases ?? [])
            .map(
              (item) => {
                "remote_id": item.id,
                "docket_id": item.docketId,
                "customer_id": customerId,
                "shopfront": resolvedShopfrontName,
                "date": item.date,
                "product": item.product,
                "qty": item.qty,
                "price": item.price,
                "price_inc": item.priceInc ?? item.price,
                "stock_id": item.stockId,
                "goods_tax": item.goodsTax,
              },
            )
            .toList(),
      );
    } on Exception catch (error) {
      return Future.error(error);
    }
  }

  @override
  Future<({bool hasMore, int? nextCursor})> fetchAndSaveCustomerTransactionsByType({
    required int customerId,
    required String transactionType,
    int pageSize = 500,
    int? cursor,
  }) async {
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

      // Build request body with optional cursor
      final body = <String, dynamic>{
        "transaction_type": transactionType,
        "page_size": pageSize,
      };
      if (cursor != null) {
        body["cursor"] = cursor;
      }

      final response = await DataAgentImpl.instance.fetchCustomerTransactions(
        resolvedIp,
        resolvedPort,
        resolvedShopfrontId,
        customerId,
        resolvedApiKey,
        body,
      );

      logger.d('Fetched $transactionType for customer $customerId: success=${response.success}, hasMore=${response.hasMore}');

      if (!response.success) {
        return Future.error(response.message);
      }

      // Map API response to local DB format based on transaction type
      List<Map<String, dynamic>> transactions = [];
      
      switch (transactionType.toLowerCase()) {
        case 'purchase':
          transactions = (response.data.purchases ?? [])
              .map((item) => {
                    "remote_id": item.id,
                    "docket_id": item.docketId,
                    "customer_id": customerId,
                    "shopfront": resolvedShopfrontName,
                    "date": item.date,
                    "product": item.product,
                    "qty": item.qty,
                    "price": item.price,
                    "price_inc": item.priceInc ?? item.price,
                    "stock_id": item.stockId,
                    "goods_tax": item.goodsTax,
                  })
              .toList();
          break;
        case 'credit':
          transactions = (response.data.credit ?? [])
              .map((item) => {
                    "remote_id": item.id,
                    "customer_id": customerId,
                    "shopfront": resolvedShopfrontName,
                    "date": item.date,
                    "credit_id": item.creditId,
                    "source": item.source,
                    "credit_type": item.creditType,
                    "amount": item.amount,
                  })
              .toList();
          break;
        case 'invoice':
          transactions = (response.data.invoices ?? [])
              .map((item) => {
                    "remote_id": item.id,
                    "customer_id": customerId,
                    "shopfront": resolvedShopfrontName,
                    "date": item.date,
                    "invoice_no": item.invoiceNo,
                    "inv_total": item.invTotal,
                    "amount_owing": item.amountOwing,
                  })
              .toList();
          break;
        case 'ivpay':
          transactions = (response.data.ivPay ?? [])
              .map((item) => {
                    "remote_id": item.id,
                    "customer_id": customerId,
                    "shopfront": resolvedShopfrontName,
                    "date": item.date,
                    "invoice_no": item.invoiceNo,
                    "payment_no": item.paymentNo,
                    "trn": item.trn,
                    "discount": item.discount,
                    "amount_paid": item.amountPaid,
                  })
              .toList();
          break;
        case 'layby':
          transactions = (response.data.laybys ?? [])
              .map((item) => {
                    "remote_id": item.id,
                    "customer_id": customerId,
                    "shopfront": resolvedShopfrontName,
                    "date": item.date,
                    "layby_no": item.laybyNo,
                    "last_payment": item.lastPayment,
                    "total": item.total,
                    "amount_owing": item.amountOwing,
                  })
              .toList();
          break;
        case 'lbpay':
          transactions = (response.data.lbPay ?? [])
              .map((item) => {
                    "remote_id": item.id,
                    "customer_id": customerId,
                    "shopfront": resolvedShopfrontName,
                    "date": item.date,
                    "layby_no": item.laybyNo,
                    "payment_no": item.paymentNo,
                    "amount_paid": item.amountPaid,
                    "payment_type": item.paymentType,
                  })
              .toList();
          break;
        case 'cso':
          transactions = (response.data.cso ?? [])
              .map((item) => {
                    "remote_id": item.id,
                    "customer_id": customerId,
                    "shopfront": resolvedShopfrontName,
                    "date": item.date,
                    "product": item.product,
                    "sell": item.sell,
                    "qty": item.qty,
                    "status": item.status,
                    "stock_id": item.stockId,
                  })
              .toList();
          break;
        case 'soquote':
          transactions = (response.data.soQuote ?? [])
              .map((item) => {
                    "remote_id": item.id,
                    "customer_id": customerId,
                    "shopfront": resolvedShopfrontName,
                    "date": item.date,
                    "salesorder_no": item.salesorderNo,
                    "type": item.type,
                    "status": item.status,
                    "total": item.total,
                    "owing": item.owing,
                  })
              .toList();
          break;
        case 'sopay':
          transactions = (response.data.soPay ?? [])
              .map((item) => {
                    "remote_id": item.id,
                    "customer_id": customerId,
                    "shopfront": resolvedShopfrontName,
                    "date": item.date,
                    "salesorder_no": item.salesorderNo,
                    "payment_no": item.paymentNo,
                    "amount_paid": item.amountPaid,
                    "payment_type": item.paymentType,
                  })
              .toList();
          break;
        default:
          throw Exception('Unknown transaction type: $transactionType');
      }

      // If cursor is provided, append to existing data; otherwise replace
      if (cursor != null) {
        await LocalDbDAO.instance.appendCustomerTransactionsByType(
          shopfront: resolvedShopfrontName,
          customerId: customerId,
          transactionType: transactionType,
          transactions: transactions,
        );
      } else {
        await LocalDbDAO.instance.replaceCustomerTransactionsByType(
          shopfront: resolvedShopfrontName,
          customerId: customerId,
          transactionType: transactionType,
          transactions: transactions,
        );
      }

      // Return pagination info
      return (
        hasMore: response.hasMore ?? false,
        nextCursor: response.nextCursor,
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
      ),
      LocalDbDAO.instance.getCustomerCredit(
        shopfront: resolvedShopfront,
        customerId: customerId,
      ),
      LocalDbDAO.instance.getCustomerInvoices(
        shopfront: resolvedShopfront,
        customerId: customerId,
      ),
      LocalDbDAO.instance.getCustomerIvPay(
        shopfront: resolvedShopfront,
        customerId: customerId,
      ),
      LocalDbDAO.instance.getCustomerLaybys(
        shopfront: resolvedShopfront,
        customerId: customerId,
      ),
      LocalDbDAO.instance.getCustomerLbPay(
        shopfront: resolvedShopfront,
        customerId: customerId,
      ),
      LocalDbDAO.instance.getCustomerCso(
        shopfront: resolvedShopfront,
        customerId: customerId,
      ),
      LocalDbDAO.instance.getCustomerSoQuote(
        shopfront: resolvedShopfront,
        customerId: customerId,
      ),
      LocalDbDAO.instance.getCustomerSoPay(
        shopfront: resolvedShopfront,
        customerId: customerId,
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
      pagination: const {},
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
