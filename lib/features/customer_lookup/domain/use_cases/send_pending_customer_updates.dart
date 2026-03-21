import 'dart:convert';

import '../../../../entities/response/customer_update_response.dart';
import '../../../../local_db/local_db_dao.dart';
import '../../../../utils/internet_connection_utils.dart';
import '../../../../utils/log_utils.dart';
import '../repositories/customer_lookup_repo.dart';

class SendPendingCustomerUpdates {
  final CustomerLookupRepo repository;

  SendPendingCustomerUpdates(this.repository);

  Future<Map<String, dynamic>> call(String shopfront) async {
    try {
      if (!await InternetConnectionUtils.instance.checkInternetConnection()) {
        return Future.error("Please connect to a network!");
      }

      final pending = await LocalDbDAO.instance.getPendingCustomerUpdates(
        shopfront,
        action: 'update',
      );
      if (pending.isEmpty) {
        return {
          'hasConflicts': false,
          'message': 'No pending customer updates.',
        };
      }

      // Detect conflicts before sending
      await LocalDbDAO.instance.detectPendingCustomerConflicts(shopfront);
      
      // Re-fetch to get updated conflict status (null = get all, regardless of conflict)
      final refreshedPending = await LocalDbDAO.instance.getPendingCustomerUpdates(
        shopfront,
        action: 'update',
      );
      
      // Split into conflicting and non-conflicting
      final conflicting = refreshedPending.where((e) => e.hasConflict).toList();
      final toSend = refreshedPending.where((e) => !e.hasConflict).toList();
      
      logger.d('After conflict detection: ${refreshedPending.length} total, ${conflicting.length} conflicts, ${toSend.length} to send');
      for (final entry in refreshedPending) {
        logger.d('  - Customer #${entry.customerId}: hasConflict=${entry.hasConflict}');
      }
      
      if (toSend.isEmpty) {
        logger.d('All items have conflicts, returning early');
        return {
          'hasConflicts': true,
          'conflicts': conflicting.length,
          'message': '${conflicting.length} update(s) have conflicts. Please review them.',
        };
      }

      final List<int> pendingIds = [];
      final List<Map<String, dynamic>> batchItems = [];

      for (final entry in toSend) {
        pendingIds.add(entry.id);
        final payload = Map<String, dynamic>.from(entry.payload);
        final items = payload['items'];
        if (items is! List) continue;
        for (final raw in items) {
          if (raw is! Map) continue;
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
        }
      }

      if (batchItems.isEmpty) {
        return {
          'hasConflicts': false,
          'message': 'No pending customer updates.',
        };
      }

      final Map<String, dynamic> batchPayload = {'items': batchItems};
      final String payloadJson = jsonEncode(batchPayload);
      logger.d('Pending customer update items batched: ${batchItems.length}');
      _printInChunks(
        'Sending pending customer update payload: $payloadJson',
      );

      final CustomerUpdateResponse response =
          await repository.updateCustomerDetails(batchPayload);

      if (response.success && response.skipped == 0) {
        await LocalDbDAO.instance.deletePendingCustomerUpdates(pendingIds);
      } else {
        for (final id in pendingIds) {
          await LocalDbDAO.instance.setPendingCustomerUpdateError(
            id: id,
            errorMessage: response.message,
          );
        }
      }

      final int failed = response.skipped > 0
          ? response.skipped
          : (response.success ? 0 : pendingIds.length);
      final bool hasFailures = failed > 0;
      return {
        'hasConflicts': false,
        'updated': response.updated,
        'failed': failed,
        'message': hasFailures
            ? 'Some customer updates failed to send.'
            : 'Pending customer updates sent.',
      };
    } catch (e) {
      return Future.error("Failed to send pending customer updates: $e");
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