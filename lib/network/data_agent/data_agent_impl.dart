import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:rmstock_scanner/entities/response/connect_shopfront_response.dart';
import 'package:rmstock_scanner/entities/response/discover_response.dart';
import 'package:rmstock_scanner/entities/response/paircode_response.dart';
import 'package:rmstock_scanner/entities/response/pair_response.dart';
import 'package:rmstock_scanner/entities/response/picture_upload_response.dart';
import 'package:rmstock_scanner/entities/response/shopfronts_api_response.dart';
import 'package:rmstock_scanner/entities/response/stock_lookup_api_response.dart';
import 'package:rmstock_scanner/entities/response/stocktake_commit_response.dart';
import 'package:rmstock_scanner/entities/response/stocktake_initcheck_response.dart';
import 'package:rmstock_scanner/entities/response/stock_update_response.dart';
import 'package:rmstock_scanner/entities/response/validate_response.dart';
import 'package:rmstock_scanner/network/api/api_service.dart';
import 'package:rmstock_scanner/network/data_agent/data_agent.dart';
import '../../entities/response/error_response.dart';
import '../../utils/log_utils.dart';

class DataAgentImpl implements DataAgent {
  DataAgentImpl._();

  static final DataAgentImpl _instance = DataAgentImpl._();
  static DataAgentImpl get instance => _instance;

  //Error config for fetching
  Object throwExceptionForAPIErrors(dynamic error) {
    if (error is DioException) {
      if (error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.sendTimeout) {
        return "Unable to connect to the server. Please check your internet connection and try again.";
      }
      if (error.response?.data is Map<String, dynamic>) {
        try {
          final errorResponse = ErrorResponse.fromJson(
            jsonDecode(error.response.toString()),
          );
          return errorResponse.message;
        } catch (error) {
          return error.toString();
        }
      }
      return error.response.toString();
    }
    return error.toString();
  }

  @override
  Future<DiscoverResponse> discoverHost(String ip, int port) async {
    try {
      final apiService = _createApiService(ip, port);
      return await apiService.discoverHost().asStream().map((event) => event).first;
    } on Exception catch (error) {
      logger.e('Error discovering host from network: $error');
      return Future.error(throwExceptionForAPIErrors(error));
    }
  }

  @override
  Future<PaircodeResponse> getPairCodes(String ip, int port) async {
    try {
      final apiService = _createApiService(ip, port);
      return await apiService.getPairCodes().asStream().map((event) => event).first;
    } on Exception catch (error) {
      logger.e('Error getting pair code from network: $error');
      return Future.error(throwExceptionForAPIErrors(error));
    }
  }

  @override
  Future<PairResponse> pairDevice(
    String ip,
    int port,
    Map<String, dynamic> body,
  ) async {
    try {
      final apiService = _createApiService(ip, port);
      return await apiService.pairDevice(body).asStream().map((event) => event).first;
    } on Exception catch (error) {
      logger.e('Error pairing device from network: $error');
      return Future.error(throwExceptionForAPIErrors(error));
    }
  }

  @override
  Future<ShopfrontsApiResponse> getShopfronts(
    String ip,
    int port,
    String apiKey,
  ) async {
    try {
      final apiService = _createApiService(ip, port);
      return await apiService.getShopfronts(apiKey).asStream().map((event) => event).first;
    } on Exception catch (error) {
      logger.e('Error getting shopfronts from network: $error');
      return Future.error(throwExceptionForAPIErrors(error));
    }
  }

  @override
  Future<ConnectShopfrontResponse> connectShopfront(
    String ip,
    int port,
    String shopfrontId,
    String apiKey,
  ) async {
    try {
      final apiService = _createApiService(ip, port);
      return await apiService.connectShopfront(
        shopfrontId,
        apiKey,
      ).asStream().map((event) => event).first;
    } on Exception catch (error) {
      logger.e('Error connecting shopfront from network: $error');
      return Future.error(throwExceptionForAPIErrors(error));
    }
  }

  @override
  Future<StockLookupApiResponse> fetchShopfrontStocks(
    String ip,
    int port,
    String shopfrontId,
    String apiKey,
    Map<String, dynamic> body,
  ) async {
    try {
      final apiService = _createApiService(ip, port);
      return await apiService.fetchShopfrontStocks(
        shopfrontId,
        apiKey,
        body,
      ).asStream().map((event) => event).first;
    } on Exception catch (error) {
      logger.e('Error fetching shopfront stocks from network: $error');
      return Future.error(throwExceptionForAPIErrors(error));
    }
  }

  @override
  Future<StockUpdateResponse> updateShopfrontStock(
    String ip,
    int port,
    String shopfrontId,
    String apiKey,
    Map<String, dynamic> body,
  ) async {
    try {
      final apiService = _createApiService(ip, port);
      return await apiService.updateShopfrontStock(
        shopfrontId,
        apiKey,
        body,
      ).asStream().map((event) => event).first;
    } on Exception catch (error) {
      logger.e('Error updating shopfront stock from network: $error');
      return Future.error(throwExceptionForAPIErrors(error));
    }
  }

  @override
  Future<PictureUploadResponse> uploadShopfrontPicture(
    String ip,
    int port,
    String shopfrontId,
    int stockId,
    String apiKey,
    List<int> jpgBytes,
  ) async {
    try {
      final apiService = _createApiService(ip, port);
      return await apiService.uploadShopfrontPicture(
        shopfrontId,
        stockId,
        apiKey,
        jpgBytes,
      ).asStream().map((event) => event).first;
    } on Exception catch (error) {
      logger.e('Error uploading shopfront picture from network: $error');
      return Future.error(throwExceptionForAPIErrors(error));
    }
  }

  @override
  Future<StocktakeInitcheckResponse> stocktakeInitCheck(
    String ip,
    int port,
    String shopfrontId,
    String apiKey,
    Map<String, dynamic> body,
  ) async {
    try {
      final apiService = _createApiService(ip, port);
      return await apiService.stocktakeInitCheck(
        shopfrontId,
        apiKey,
        body,
      ).asStream().map((event) => event).first;
    } on Exception catch (error) {
      logger.e('Error calling stocktake init check from network: $error');
      return Future.error(throwExceptionForAPIErrors(error));
    }
  }

  @override
  Future<StocktakeCommitResponse> stocktakeCommit(
    String ip,
    int port,
    String shopfrontId,
    String apiKey,
    Map<String, dynamic> body,
  ) async {
    try {
      final apiService = _createApiService(ip, port);
      return await apiService.stocktakeCommit(
        shopfrontId,
        apiKey,
        body,
      ).asStream().map((event) => event).first;
    } on Exception catch (error) {
      logger.e('Error calling stocktake commit from network: $error');
      return Future.error(throwExceptionForAPIErrors(error));
    }
  }

  @override
  Future<ValidateResponse> validate(String ip, int port, String apiKey) async {
    try {
      final apiService = _createApiService(ip, port);
      return await apiService.validate(apiKey).asStream().map((event) => event).first;
    } on Exception catch (error) {
      logger.e('Error validating connection from network: $error');
      return Future.error(throwExceptionForAPIErrors(error));
    }
  }

  ApiService _createApiService(String ip, int port) {
    final cleanedIp = ip
        .trim()
        .replaceFirst(RegExp(r'^https?://'), '')
        .replaceAll(RegExp(r'/$'), '');

    String baseUrl = "http://$cleanedIp:$port/api";

    logger.d(baseUrl);
    return ApiService(Dio(BaseOptions(baseUrl: baseUrl)));
  }
}
