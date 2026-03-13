import '../../../../local_db/local_db_dao.dart';

class GetPendingStockUpdatesCount {
  Future<int> call(String shopfront) async {
    try {
      return await LocalDbDAO.instance.getPendingStockUpdatesCount(shopfront);
    } catch (e) {
      return Future.error("Failed to load pending stock update count: $e");
    }
  }
}
