import '../../../../local_db/local_db_dao.dart';

class ResolveCustomerCreateConflicts {
  Future<void> call({
    required String shopfront,
    required bool duplicate,
  }) async {
    try {
      final conflicts = await LocalDbDAO.instance.getPendingCustomerUpdates(
        shopfront,
        action: 'create',
        conflictOnly: true,
      );

      if (conflicts.isEmpty) return;

      if (!duplicate) {
        final ids = conflicts.map((e) => e.id).toList();
        await LocalDbDAO.instance.deletePendingCustomerUpdates(ids);
        return;
      }

      for (final entry in conflicts) {
        final payload = Map<String, dynamic>.from(entry.payload);
        final items = payload['items'];
        if (items is! List || items.isEmpty) continue;

        final item = Map<String, dynamic>.from(items.first as Map);
        final int newCustomerId =
            await LocalDbDAO.instance.getNextCustomerId(shopfront);
        int nextAddressId =
            await LocalDbDAO.instance.getNextCustomerAddressId(shopfront);

        item['customerId'] = newCustomerId;
        item['customer_id'] = newCustomerId;

        if (item['addresses'] is List) {
          final addresses = item['addresses'] as List;
          for (final raw in addresses) {
            final addr = Map<String, dynamic>.from(raw as Map);
            addr['customerId'] = newCustomerId;
            addr['customer_id'] = newCustomerId;
            addr['addressId'] = nextAddressId;
            addr['address_id'] = nextAddressId;
            nextAddressId += 1;
          }
        }

        payload['items'] = [item];

        await LocalDbDAO.instance.updatePendingCustomerPayload(
          id: entry.id,
          customerId: newCustomerId,
          payload: payload,
        );
      }

      await LocalDbDAO.instance.applyPendingCustomerUpdates(shopfront);
    } catch (e) {
      return Future.error("Failed to resolve customer conflicts: $e");
    }
  }
}
