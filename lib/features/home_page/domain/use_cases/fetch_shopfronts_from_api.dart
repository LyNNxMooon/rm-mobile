import 'package:rmstock_scanner/entities/response/shopfront_response.dart';
import 'package:rmstock_scanner/features/home_page/domain/repositories/home_repo.dart';
import 'package:rmstock_scanner/utils/internet_connection_utils.dart';

class FetchShopfrontsFromApi {
  final HomeRepo repository;

  FetchShopfrontsFromApi(this.repository);

  Future<ShopfrontResponse> call(String ip, int port, String apiKey) async {
    try {
      if (await InternetConnectionUtils.instance.checkInternetConnection()) {
        return await repository.fetchShopfrontsFromApi(ip, port, apiKey);
      } else {
        return Future.error("Please connect to a network!");
      }
    } catch (error) {
      return Future.error(error);
    }
  }
}
