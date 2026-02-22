import 'package:rmstock_scanner/entities/vos/network_server_vo.dart';
import 'package:rmstock_scanner/features/home_page/domain/repositories/home_repo.dart';

import '../../../../utils/internet_connection_utils.dart';

class FetchNetworkPcs {
  HomeRepo repository;

  FetchNetworkPcs(this.repository);

  Future<List<NetworkServerVO>> call() async {
    try {
      if (await InternetConnectionUtils.instance.checkInternetConnection()) {
        return repository.fetchNetworkServers();
      } else {
        return Future.error("Please connect to a network!");
      }
    } catch (error) {
      return Future.error(error);
    }
  }
}
