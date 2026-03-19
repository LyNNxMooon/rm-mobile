import '../../../../entities/vos/pending_customer_creation_vo.dart';
import '../../../../local_db/local_db_dao.dart';

class GetPendingCustomerCreations {
  Future<List<PendingCustomerCreationVO>> call(String shopfront) async {
    try {
      return await LocalDbDAO.instance.getPendingCustomerCreations(shopfront);
    } catch (e) {
      return Future.error("Failed to load pending customer creations: $e");
    }
  }
}
