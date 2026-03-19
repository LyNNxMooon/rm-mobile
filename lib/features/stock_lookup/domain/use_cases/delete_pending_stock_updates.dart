import '../../../../local_db/local_db_dao.dart';

class DeletePendingStockUpdates {
  Future<void> call(List<int> ids) async {
    try {
      await LocalDbDAO.instance.deletePendingStockUpdates(ids);
    } catch (e) {
      return Future.error("Failed to delete pending stock updates: $e");
    }
  }
}
