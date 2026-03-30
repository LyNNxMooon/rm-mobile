import '../../../../local_db/local_db_dao.dart';

/// Use case for deleting a sale session
class DeleteSaleSession {
  /// Delete a sale session by ID
  Future<void> call({required int sessionId}) async {
    await LocalDbDAO.instance.deleteSaleSession(sessionId);
  }
}
