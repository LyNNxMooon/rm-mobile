import '../../../../local_db/local_db_dao.dart';

class GetPendingCustomerCreationsCount {
  Future<int> call(String shopfront) async {
    try {
      return await LocalDbDAO.instance.getPendingCustomerCreationsCount(shopfront);
    } catch (e) {
      return Future.error(
        "Failed to load pending customer creation count: $e",
      );
    }
  }
}
