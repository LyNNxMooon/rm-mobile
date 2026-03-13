import '../../../../entities/response/customer_create_response.dart';
import '../../../../entities/response/customer_update_response.dart';
import '../../../../local_db/local_db_dao.dart';
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
}
