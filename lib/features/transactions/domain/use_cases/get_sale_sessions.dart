import '../../../../local_db/local_db_dao.dart';
import '../../../../entities/vos/sale_session_vo.dart';

/// Use case for getting saved sale sessions
class GetSaleSessions {
  /// Get all sale sessions for a given shopfront and session type
  Future<List<SaleSessionVO>> call({
    required String shopfront,
    required String sessionType,
  }) async {
    if (shopfront.isEmpty) return [];

    final sessionsData = await LocalDbDAO.instance.getSaleSessions(
      shopfront: shopfront,
      sessionType: sessionType,
    );

    if (sessionsData.isEmpty) return [];

    return sessionsData.map((e) => SaleSessionVO.fromMap(e)).toList();
  }
}
