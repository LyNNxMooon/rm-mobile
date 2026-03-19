import '../../../../local_db/local_db_dao.dart';

class DeletePendingCustomerUpdates {
  Future<void> call(List<int> ids) async {
    try {
      await LocalDbDAO.instance.deletePendingCustomerUpdates(ids);
    } catch (e) {
      return Future.error("Failed to delete pending customer updates: $e");
    }
  }
}
