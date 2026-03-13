import '../../../../local_db/local_db_dao.dart';

class GetPendingCustomerUpdatesCount {
  Future<int> call(String shopfront) async {
    try {
      return await LocalDbDAO.instance.getPendingCustomerUpdatesCount(shopfront);
    } catch (e) {
      return Future.error("Failed to load pending customer update count: $e");
    }
  }
}
