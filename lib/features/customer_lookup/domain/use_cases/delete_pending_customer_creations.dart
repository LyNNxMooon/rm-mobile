import '../../../../local_db/local_db_dao.dart';

class DeletePendingCustomerCreations {
  Future<void> call(List<int> ids) async {
    try {
      await LocalDbDAO.instance.deletePendingCustomerCreations(ids);
    } catch (e) {
      return Future.error("Failed to delete pending customer creations: $e");
    }
  }
}
