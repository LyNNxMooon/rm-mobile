import '../local_db/local_db_dao.dart';

class NetworkCredentialsCheckUtils {
  NetworkCredentialsCheckUtils._();

  static final NetworkCredentialsCheckUtils _instance =
      NetworkCredentialsCheckUtils._();

  static NetworkCredentialsCheckUtils get instance => _instance;

  Future<bool> isRequiredNetworkCredentials({
    required String ipAddress,
  }) async {
    return await LocalDbDAO.instance.getNetworkCredential(ip: ipAddress).then((
      value,
    ) {
      if (value == null) {
        return false;
      } else {
        return true;
      }
    });
  }
}
