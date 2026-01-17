import 'package:rmstock_scanner/entities/vos/network_computer_vo.dart';
import 'package:rmstock_scanner/features/home_page/domain/repositories/home_repo.dart';

import '../../../../utils/internet_connection_utils.dart';

class FetchNetworkPcs {
  HomeRepo repository;

  FetchNetworkPcs(this.repository);

  Future<List<NetworkComputerVO>> call() async {
    try {
      if (await InternetConnectionUtils.instance.checkInternetConnection()) {
        return repository.fetchNetworkPCs();
      } else {
        return Future.error("Please connect to a network!");
      }
    } catch (error) {
      return Future.error(error);
    }
  }
}
