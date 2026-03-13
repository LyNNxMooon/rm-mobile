import '../../../../entities/vos/pending_customer_update_vo.dart';
import '../../../../local_db/local_db_dao.dart';

class GetPendingCustomerUpdates {
  Future<List<PendingCustomerUpdateVO>> call(
    String shopfront, {
    String? action,
    bool? conflictOnly,
  }) async {
    try {
      return await LocalDbDAO.instance.getPendingCustomerUpdates(
        shopfront,
        action: action,
        conflictOnly: conflictOnly,
      );
    } catch (e) {
      return Future.error("Failed to load pending customer updates: $e");
    }
  }
}
