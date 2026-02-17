import 'package:rmstock_scanner/entities/response/pair_response.dart';
import 'package:rmstock_scanner/features/home_page/domain/repositories/home_repo.dart';
import 'package:rmstock_scanner/utils/internet_connection_utils.dart';

class PairDevice {
  final HomeRepo repository;

  PairDevice(this.repository);

  Future<PairResponse> call({
    required String ip,
    required String hostName,
    required int port,
    required String pairingCode,
  }) async {
    try {
      if (await InternetConnectionUtils.instance.checkInternetConnection()) {
        return await repository.pairDevice(
          ip: ip,
          hostName: hostName,
          port: port,
          pairingCode: pairingCode,
        );
      } else {
        return Future.error("Please connect to a network!");
      }
    } catch (error) {
      return Future.error(error);
    }
  }
}
