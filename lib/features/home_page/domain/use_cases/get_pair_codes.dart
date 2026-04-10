import 'package:rmmobile/entities/response/paircode_response.dart';
import 'package:rmmobile/features/home_page/domain/repositories/home_repo.dart';
import 'package:rmmobile/utils/internet_connection_utils.dart';

class GetPairCodes {
  final HomeRepo repository;

  GetPairCodes(this.repository);

  Future<PaircodeResponse> call(String ip, int port) async {
    try {
      if (await InternetConnectionUtils.instance.checkInternetConnection()) {
        return await repository.getPairCodes(ip, port);
      } else {
        return Future.error("Please connect to a network!");
      }
    } catch (error) {
      return Future.error(error);
    }
  }
}
