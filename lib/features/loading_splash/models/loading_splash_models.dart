import 'package:rmstock_scanner/features/loading_splash/domain/repositories/loading_splash_repo.dart';

import '../../../local_db/local_db_dao.dart';
import '../../../network/LAN_sharing/lan_network_service_impl.dart';

class LoadingSplashModels implements LoadingSplashRepo {
  @override
  Future<void> checksConnection(
    String ip,
    String path,
    String? userName,
    String? pwd,
  ) async {
    try {
      return await LanNetworkServiceImpl.instance.writeToSelectedFolder(
        address: ip,
        fullPath: path,
        username: userName ?? "Guest",
        password: pwd ?? "",
      );
    } on Exception catch (error) {
      return Future.error(error);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getSavedPaths() async {
    try {
      return LocalDbDAO.instance.getAllNetworkPaths();
    } on Exception catch (error) {
      return Future.error(error);
    }
  }
}
