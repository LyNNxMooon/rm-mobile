import 'package:dio/dio.dart' hide Headers;
import 'package:retrofit/retrofit.dart';
import 'package:rmstock_scanner/entities/response/stock_list_response.dart';
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
}
