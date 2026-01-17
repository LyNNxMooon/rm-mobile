import '../local_db/local_db_dao.dart';

class PathCheckUtils {
  PathCheckUtils._();

  static final PathCheckUtils _instance = PathCheckUtils._();

  static PathCheckUtils get instance => _instance;

  Future<bool> isPathAlreadyExists({required String ipAddress}) async {
    return await LocalDbDAO.instance.getSinglePathByIp(ipAddress).then((value) {
      if (value == null) {
        return false;
      } else {
        return true;
      }
    });
  }
}
