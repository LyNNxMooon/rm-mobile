import 'package:rmstock_scanner/features/loading_splash/domain/repositories/loading_splash_repo.dart';
import 'package:rmstock_scanner/utils/global_var_utils.dart';

import '../../../local_db/local_db_dao.dart';
import '../../../network/LAN_sharing/lan_network_service_impl.dart';
import '../../../network/data_agent/data_agent_impl.dart';

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
        username: userName ?? AppGlobals.instance.defaultUserName,
        password: pwd ?? AppGlobals.instance.defaultPwd,
      );
    } on Exception catch (error) {
      return Future.error(error);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getSavedPaths() async {
    try {
      final savedIp = await LocalDbDAO.instance.getHostIpAddress();
      final savedPort = await LocalDbDAO.instance.getHostPort();
      final savedApiKey = await LocalDbDAO.instance.getApiKey();

      if ((savedIp ?? "").isEmpty ||
          (savedPort ?? "").isEmpty ||
          (savedApiKey ?? "").isEmpty) {
        return [];
      }

      return [
        {
          'path': savedIp,
          'host_ip': savedIp,
          'port': savedPort,
        },
      ];

      // Old setup disabled:
      // return LocalDbDAO.instance.getAllNetworkPaths();
    } on Exception catch (error) {
      return Future.error(error);
    }
  }

  @override
  Future<bool> validateConnection({
    required String ip,
    required int port,
    required String apiKey,
  }) async {
    try {
      final response = await DataAgentImpl.instance.validate(ip, port, apiKey);
      return response.success;
    } on Exception catch (error) {
      return Future.error(error);
    }
  }
}
