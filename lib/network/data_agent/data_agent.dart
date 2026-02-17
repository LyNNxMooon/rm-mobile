import 'package:rmstock_scanner/entities/response/discover_response.dart';
import 'package:rmstock_scanner/entities/response/paircode_response.dart';
import 'package:rmstock_scanner/entities/response/pair_response.dart';
import 'package:rmstock_scanner/entities/response/shopfronts_api_response.dart';

abstract class DataAgent {


   
  Future<DiscoverResponse> discoverHost(String ip, int port);

  Future<PaircodeResponse> getPairCodes(String ip, int port);

  Future<PairResponse> pairDevice(
    String ip,
    int port,
    Map<String, dynamic> body,
  );

  Future<ShopfrontsApiResponse> getShopfronts(
    String ip,
    int port,
    String apiKey,
  );

}
