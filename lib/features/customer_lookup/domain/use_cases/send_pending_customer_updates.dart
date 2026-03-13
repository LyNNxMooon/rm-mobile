import '../../../../entities/response/customer_create_response.dart';
import '../../../../entities/response/customer_update_response.dart';
import '../../../../entities/vos/pending_customer_update_vo.dart';
import '../../../../local_db/local_db_dao.dart';
import '../../../../local_db/sqlite/sqlite_constants.dart';
import '../../../../utils/internet_connection_utils.dart';
import '../repositories/customer_lookup_repo.dart';

class SendPendingCustomerUpdates {
  final CustomerLookupRepo repository;

  SendPendingCustomerUpdates(this.repository);

  Future<Map<String, dynamic>> call(String shopfront) async {
    try {
      if (!await InternetConnectionUtils.instance.checkInternetConnection()) {
        return Future.error("Please connect to a network!");
      }

      await _normalizePendingCreateIds(shopfront);

      final pendingConflicts = await LocalDbDAO.instance.getPendingCustomerUpdates(
        shopfront,
        action: 'create',
        conflictOnly: true,
      );

      if (pendingConflicts.isNotEmpty) {
        return {
          'hasConflicts': true,
          'message': 'Customer create conflicts need review.',
        };
      }

      final pending = await LocalDbDAO.instance.getPendingCustomerUpdates(
        shopfront,
      );
      if (pending.isEmpty) {
        return {
          'hasConflicts': false,
          'message': 'No pending customer updates.',
        };
      }

      final List<int> sentIds = [];
      int created = 0;
      int updated = 0;
      int failed = 0;

      for (final entry in pending) {
        if (entry.action == 'create') {
          final CustomerCreateResponse response =
              await repository.createCustomer(entry.payload);
          if (response.success) {
            created += 1;
            sentIds.add(entry.id);
          } else {
            failed += 1;
          }
        } else {
          final CustomerUpdateResponse response =
              await repository.updateCustomerDetails(entry.payload);
          if (response.success) {
            updated += 1;
            sentIds.add(entry.id);
          } else {
            failed += 1;
          }
        }
      }

      if (sentIds.isNotEmpty) {
        await LocalDbDAO.instance.deletePendingCustomerUpdates(sentIds);
      }

      final bool hasFailures = failed > 0;
      return {
        'hasConflicts': false,
        'created': created,
        'updated': updated,
        'failed': failed,
        'message': hasFailures
            ? 'Some customer updates failed to send.'
            : 'Pending customer updates sent.',
      };
    } catch (e) {
      return Future.error("Failed to send pending customer updates: $e");
    }
  }

  Future<void> _normalizePendingCreateIds(String shopfront) async {
    final maxRemoteValue = await LocalDbDAO.instance.getAppConfig(
      '$kCustomerMaxIdPrefix$shopfront',
    );
    int maxRemoteId = int.tryParse(maxRemoteValue ?? '') ?? 0;
    if (maxRemoteId <= 0) return;

    final pendingCreates = await LocalDbDAO.instance.getPendingCustomerUpdates(
      shopfront,
      action: 'create',
      conflictOnly: false,
    );

    if (pendingCreates.isEmpty) return;

    final entries = List<PendingCustomerUpdateVO>.from(pendingCreates)
      ..sort(
        (a, b) => a.createdAt.compareTo(b.createdAt),
      );

    for (final entry in entries) {
      if (entry.customerId > maxRemoteId) {
        maxRemoteId = entry.customerId;
        continue;
      }

      maxRemoteId += 1;
      final payload = Map<String, dynamic>.from(entry.payload);
      final items = payload['items'];
      if (items is! List || items.isEmpty) continue;

      final item = Map<String, dynamic>.from(items.first as Map);
      int nextAddressId =
          await LocalDbDAO.instance.getNextCustomerAddressId(shopfront);

      item['customerId'] = maxRemoteId;
      item['customer_id'] = maxRemoteId;

      final barcodeValue = item['barcode'];
      final barcodeText = barcodeValue is String ? barcodeValue.trim() : '';
      final isNumericBarcode = int.tryParse(barcodeText) != null;
      if (barcodeText.isEmpty || isNumericBarcode) {
        final newBarcode =
            await LocalDbDAO.instance.getNextNumericBarcode(shopfront);
        item['barcode'] = newBarcode;
      }

      if (item['addresses'] is List) {
        final addresses = item['addresses'] as List;
        for (final raw in addresses) {
          final addr = Map<String, dynamic>.from(raw as Map);
          addr['customerId'] = maxRemoteId;
          addr['customer_id'] = maxRemoteId;
          addr['addressId'] = nextAddressId;
          addr['address_id'] = nextAddressId;
          nextAddressId += 1;
        }
      }

      payload['items'] = [item];

      await LocalDbDAO.instance.updatePendingCustomerPayload(
        id: entry.id,
        customerId: maxRemoteId,
        payload: payload,
      );
    }
  }
}
