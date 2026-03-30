import '../../../../local_db/local_db_dao.dart';

/// Use case for saving a single sales setting
class SaveSalesSetting {
  /// Save a sales setting to local database
  Future<void> call({
    required String key,
    required bool value,
  }) async {
    await LocalDbDAO.instance.saveAppConfig(key, value.toString());
  }
}
