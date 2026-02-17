import 'package:rmstock_scanner/entities/response/discover_response.dart';
import 'package:rmstock_scanner/features/home_page/domain/repositories/home_repo.dart';
import 'package:rmstock_scanner/utils/internet_connection_utils.dart';

class DiscoverHost {
  final HomeRepo repository;

  DiscoverHost(this.repository);

  Future<DiscoverResponse> call(String ip, int port) async {
    try {
      if (await InternetConnectionUtils.instance.checkInternetConnection()) {
        return await repository.discoverHost(ip, port);
      } else {
        return Future.error("Please connect to a network!");
      }
    } catch (error) {
      return Future.error(error);
    }
  }
}
