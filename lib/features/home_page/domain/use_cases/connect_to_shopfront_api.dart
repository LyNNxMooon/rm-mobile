import 'package:rmmobile/entities/response/connect_shopfront_response.dart';
import 'package:rmmobile/features/home_page/domain/repositories/home_repo.dart';
import 'package:rmmobile/utils/internet_connection_utils.dart';

class ConnectToShopfrontApi {
  final HomeRepo repository;

  ConnectToShopfrontApi(this.repository);

  Future<ConnectShopfrontResponse> call({
    required String ip,
    required int port,
    required String apiKey,
    required String shopfrontId,
    required String shopfrontName,
  }) async {
    try {
      if (await InternetConnectionUtils.instance.checkInternetConnection()) {
        return await repository.connectShopfrontFromApi(
          ip: ip,
          port: port,
          apiKey: apiKey,
          shopfrontId: shopfrontId,
          shopfrontName: shopfrontName,
        );
      } else {
        return Future.error("Please connect to a network!");
      }
    } catch (error) {
      return Future.error(error);
    }
  }
}
