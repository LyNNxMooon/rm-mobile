import 'package:dio/dio.dart' hide Headers;
import 'package:rmstock_scanner/entities/response/connect_shopfront_response.dart';
import 'package:retrofit/retrofit.dart';
import 'package:rmstock_scanner/entities/response/discover_response.dart';
import 'package:rmstock_scanner/entities/response/paircode_response.dart';
import 'package:rmstock_scanner/entities/response/pair_response.dart';
import 'package:rmstock_scanner/entities/response/shopfronts_api_response.dart';
import 'package:rmstock_scanner/entities/response/stock_list_response.dart';
import 'package:rmstock_scanner/entities/response/validate_response.dart';
import 'package:rmstock_scanner/entities/vos/stock_vo.dart';
import 'api_constants.dart';
part 'api_service.g.dart';

@RestApi()
abstract class ApiService {
  factory ApiService(Dio dio) => _ApiService(dio);

  @GET(kEndPointForStockDetails)
  @Headers(<String, dynamic>{
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  })
  Future<StockVO> fetchStockDetails(@Path(kPathParamForBarcode) String barcode);

  @POST(kEndPointForStocktake)
  @Headers(<String, dynamic>{
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  })
  Future<List<String>> fetchShopList();

  @GET(kEndPointForStockList)
  @Headers(<String, dynamic>{
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  })
  Future<StockListResponse> fetchStockList(
    @Query(kQueryParamKeyForLastStockID) String? lastStockID,
    @Query(kQueryParamKeyForPageSize) int pageSize,
  );

  @GET(kEndPointForDiscover)
  @Headers(<String, dynamic>{
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  })
  Future<DiscoverResponse> discoverHost();

  @GET(kEndPointForPairCode)
  @Headers(<String, dynamic>{
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  })
  Future<PaircodeResponse> getPairCodes();

  @POST(kEndPointForParing)
  @Headers(<String, dynamic>{
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  })
  Future<PairResponse> pairDevice(@Body() Map<String, dynamic> body);

  @GET(kEndPointForShopfronts)
  @Headers(<String, dynamic>{
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  })
  Future<ShopfrontsApiResponse> getShopfronts(@Header("x-api-key") String apiKey);

  @POST(kEndPointForConnectShopfront)
  @Headers(<String, dynamic>{
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  })
  Future<ConnectShopfrontResponse> connectShopfront(
    @Path(kPathParamForShopfrontId) String shopfrontId,
    @Header("x-api-key") String apiKey,
  );

  @POST(kEndPointForValidate)
  @Headers(<String, dynamic>{
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  })
  Future<ValidateResponse> validate(@Header("x-api-key") String apiKey);
}
