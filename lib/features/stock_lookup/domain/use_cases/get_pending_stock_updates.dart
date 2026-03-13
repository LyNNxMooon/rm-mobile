import '../../../../entities/vos/pending_stock_update_vo.dart';
import '../../../../local_db/local_db_dao.dart';

class GetPendingStockUpdates {
  Future<List<PendingStockUpdateVO>> call(String shopfront) async {
    try {
      return await LocalDbDAO.instance.getPendingStockUpdates(shopfront);
    } catch (e) {
      return Future.error("Failed to load pending stock updates: $e");
    }
  }
}
