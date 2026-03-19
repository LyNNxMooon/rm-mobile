import 'dart:convert';

import '../../../../entities/response/customer_create_response.dart';
import '../../../../local_db/local_db_dao.dart';
import '../../../../utils/internet_connection_utils.dart';
import '../repositories/customer_lookup_repo.dart';

class SendPendingCustomerCreations {
  final CustomerLookupRepo repository;

  SendPendingCustomerCreations(this.repository);

  Future<Map<String, dynamic>> call(String shopfront) async {
    try {
      if (!await InternetConnectionUtils.instance.checkInternetConnection()) {
        return Future.error("Please connect to a network!");
      }

      final pending =
          await LocalDbDAO.instance.getPendingCustomerCreations(shopfront);
      if (pending.isEmpty) {
        return {
          'message': 'No pending customer creations.',
          'created': 0,
          'failed': 0,
        };
      }

      final List<Map<String, dynamic>> batchItems = [];
      final List<int> pendingIds = [];
      final List<int> batchItemPendingIds = [];

      for (final entry in pending) {
        pendingIds.add(entry.id);
        final items = entry.payload['items'];
        if (items is! List || items.isEmpty) continue;
        for (final raw in items) {
          if (raw is Map) {
            final item = Map<String, dynamic>.from(raw);
            item.remove('customer_id');
            final addresses = item['addresses'];
            if (addresses is List) {
              for (var i = 0; i < addresses.length; i++) {
                final addr = Map<String, dynamic>.from(addresses[i] as Map);
                addr.remove('address_id');
                addr.remove('customer_id');
                addresses[i] = addr;
              }
              item['addresses'] = addresses;
            }
            batchItems.add(item);
            batchItemPendingIds.add(entry.id);
          }
        }
      }

      if (batchItems.isEmpty) {
        return {
          'message': 'No pending customer creations.',
          'created': 0,
          'failed': 0,
        };
      }

      final Map<String, dynamic> batchPayload = {'items': batchItems};
      final String payloadJson = jsonEncode(batchPayload);
      // ignore: avoid_print
      print('Pending customer creations: ${pending.length}');
      // ignore: avoid_print
      print('Pending create items batched: ${batchItems.length}');
      _printInChunks(
        'Sending pending customer creation payload: $payloadJson',
      );

      final CustomerCreateResponse response =
          await repository.createCustomer(batchPayload);

      if (response.results.isNotEmpty) {
        final Map<int, int> totalByPendingId = {};
        for (final pendingId in batchItemPendingIds) {
          totalByPendingId[pendingId] =
              (totalByPendingId[pendingId] ?? 0) + 1;
        }

        final Map<int, int> successByPendingId = {};
        final Set<int> failedPendingIds = {};

        for (final result in response.results) {
          if (result.itemIndex < 0 ||
              result.itemIndex >= batchItemPendingIds.length) {
            continue;
          }
          final pendingId = batchItemPendingIds[result.itemIndex];
          if (result.success) {
            successByPendingId[pendingId] =
                (successByPendingId[pendingId] ?? 0) + 1;
          } else {
            failedPendingIds.add(pendingId);
          }
        }

        final List<int> successIds = [];
        for (final entry in totalByPendingId.entries) {
          final int successCount = successByPendingId[entry.key] ?? 0;
          if (successCount >= entry.value && !failedPendingIds.contains(entry.key)) {
            successIds.add(entry.key);
          } else {
            failedPendingIds.add(entry.key);
          }
        }

        if (successIds.isNotEmpty) {
          await LocalDbDAO.instance.deletePendingCustomerCreations(successIds);
        }

        for (final id in failedPendingIds) {
          await LocalDbDAO.instance.setPendingCustomerCreationError(
            id: id,
            errorMessage: 'Duplicate value.',
          );
        }

        final int failedCount = failedPendingIds.length;
        return {
          'message': failedCount > 0
              ? 'Some customer creations failed to send.'
              : 'Pending customer creations sent.',
          'created': response.created,
          'failed': failedCount,
        };
      }

      if (response.success && response.failed == 0) {
        await LocalDbDAO.instance.deletePendingCustomerCreations(pendingIds);
        return {
          'message': 'Pending customer creations sent.',
          'created': response.created,
          'failed': 0,
        };
      }

      for (final id in pendingIds) {
        await LocalDbDAO.instance.setPendingCustomerCreationError(
          id: id,
          errorMessage: 'Duplicate value.',
        );
      }

      final int failedCount = response.failed > 0
          ? response.failed
          : pendingIds.length;
      return {
        'message': 'Some customer creations failed to send.',
        'created': response.created,
        'failed': failedCount,
      };
    } catch (e) {
      return Future.error("Failed to send pending customer creations: $e");
    }
  }
}

void _printInChunks(String message, {int chunkSize = 800}) {
  if (message.length <= chunkSize) {
    // ignore: avoid_print
    print(message);
    return;
  }

  for (var i = 0; i < message.length; i += chunkSize) {
    final end = (i + chunkSize < message.length) ? i + chunkSize : message.length;
    // ignore: avoid_print
    print(message.substring(i, end));
  }
}
