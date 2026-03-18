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

      for (final entry in pending) {
        final payload = entry.payload;
        final items = payload['items'];
        if (items is! List || items.isEmpty) continue;
        final item = Map<String, dynamic>.from(items.first as Map);
        final barcode = item['barcode'] as String?;
        if (barcode == null || barcode.trim().isEmpty) continue;

        final exists = await LocalDbDAO.instance.checkBarcodeExistsInCustomers(
          barcode.trim(),
          shopfront,
        );
        await LocalDbDAO.instance.setPendingCustomerCreationBarcodeMissing(
          id: entry.id,
          isMissing: !exists,
        );
      }

      final List<int> sentIds = [];
      int created = 0;
      int failed = 0;

      for (final entry in pending) {
        final CustomerCreateResponse response =
            await repository.createCustomer(entry.payload);
        if (response.success) {
          created += 1;
          sentIds.add(entry.id);
        } else {
          failed += 1;
        }
      }

      if (sentIds.isNotEmpty) {
        await LocalDbDAO.instance.deletePendingCustomerCreations(sentIds);
      }

      return {
        'message': failed > 0
            ? 'Some customer creations failed to send.'
            : 'Pending customer creations sent.',
        'created': created,
        'failed': failed,
      };
    } catch (e) {
      return Future.error("Failed to send pending customer creations: $e");
    }
  }
}
