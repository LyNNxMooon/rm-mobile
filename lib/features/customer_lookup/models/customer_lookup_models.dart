import 'package:rmstock_scanner/entities/response/paginated_customer_response.dart';
import 'package:rmstock_scanner/entities/response/staff_detail_response.dart';
import 'package:rmstock_scanner/entities/vos/customer_vo.dart';
import 'package:rmstock_scanner/features/customer_lookup/domain/entities/customer_sync_status.dart';
import 'package:rmstock_scanner/features/customer_lookup/domain/repositories/customer_lookup_repo.dart';
import 'package:rmstock_scanner/network/data_agent/data_agent_impl.dart';
import 'package:rmstock_scanner/utils/global_var_utils.dart';

import '../../../entities/vos/filter_criteria.dart';
import '../../../local_db/local_db_dao.dart';

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

      String latestSyncTimestamp = DateTime.now().toIso8601String();

      if (isFullSync) {
        yield CustomerSyncStatus(0, 1, "Starting full sync...");

        await LocalDbDAO.instance.clearCustomersForShop(resolvedShopfrontName);

        int processed = 0;
        int total = 1;
        int? afterCustomerId;
        bool hasMore = true;

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

          latestSyncTimestamp = response.syncTimestamp;
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

        latestSyncTimestamp = response.syncTimestamp;

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
}
