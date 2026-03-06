import 'dart:convert';
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:rmstock_scanner/entities/response/connect_shopfront_response.dart';
import 'package:rmstock_scanner/entities/response/authenticate_staff_response.dart';
import 'package:rmstock_scanner/entities/response/backup_list_response.dart';
import 'package:rmstock_scanner/entities/response/discover_response.dart';
import 'package:rmstock_scanner/entities/response/load_backup_response.dart';
import 'package:rmstock_scanner/entities/response/paircode_response.dart';
import 'package:rmstock_scanner/entities/response/pair_response.dart';
import 'package:rmstock_scanner/entities/response/picture_upload_response.dart';
import 'package:rmstock_scanner/entities/response/shopfronts_api_response.dart';
import 'package:rmstock_scanner/entities/response/stock_lookup_api_response.dart';
import 'package:rmstock_scanner/entities/response/customer_lookup_api_response.dart';
import 'package:rmstock_scanner/entities/response/stocktake_backup_response.dart';
import 'package:rmstock_scanner/entities/response/stocktake_commit_response.dart';
import 'package:rmstock_scanner/entities/response/stocktake_initcheck_response.dart';
import 'package:rmstock_scanner/entities/response/stocktake_limit_response.dart';
import 'package:rmstock_scanner/entities/response/stock_update_response.dart';
import 'package:rmstock_scanner/entities/response/validate_response.dart';
import 'package:rmstock_scanner/entities/response/security_groups_response.dart';
import 'package:rmstock_scanner/network/api/api_service.dart';
import 'package:rmstock_scanner/network/data_agent/data_agent.dart';
import '../../entities/response/error_response.dart';
import '../../utils/log_utils.dart';

class DataAgentImpl implements DataAgent {
  DataAgentImpl._();

  static final DataAgentImpl _instance = DataAgentImpl._();
  static DataAgentImpl get instance => _instance;
  static const Duration _connectTimeout = Duration(seconds: 6);
  static const Duration _receiveTimeout = Duration(seconds: 12);
  static const Duration _sendTimeout = Duration(seconds: 12);

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
            error.response!.data as Map<String, dynamic>,
          );
          return _formatApiError(errorResponse);
        } catch (e) {
          return e.toString();
        }
      }

      if (error.response?.data is String) {
        try {
          final decoded = jsonDecode(error.response!.data as String);
          if (decoded is Map<String, dynamic>) {
            final errorResponse = ErrorResponse.fromJson(decoded);
            return _formatApiError(errorResponse);
          }
        } catch (_) {
          // fall through
        }
      }

      return error.message ?? error.response.toString();
    }
    return error.toString();
  }

  String _formatApiError(ErrorResponse error) {
    final code = error.code ?? "";
    if (code == "TRIAL_ONLINE_REQUIRED") {
      final details = <String>[error.mainMessage];
      if ((error.validationCode ?? "").isNotEmpty) {
        details.add("Validation: ${error.validationCode}");
      }
      if ((error.validationDetail ?? "").isNotEmpty) {
        details.add(error.validationDetail!);
      }
      return details.join("\n");
    }

    if (code == "TRIAL_LIMIT_REACHED") {
      final used = error.used ?? 0;
      final limit = error.limit ?? 0;
      final remaining = error.remaining ?? 0;
      return "${error.mainMessage}\nUsed: $used / $limit\nRemaining: $remaining";
    }

    return error.mainMessage;
  }

  @override
  Future<DiscoverResponse> discoverHost(String ip, int port) async {
    try {
      final apiService = _createApiService(ip, port);
      return await apiService
          .discoverHost()
          .asStream()
          .map((event) => event)
          .first;
    } on Exception catch (error) {
      logger.e('Error discovering host from network: $error');
      return Future.error(throwExceptionForAPIErrors(error));
    }
  }

  @override
  Future<PaircodeResponse> getPairCodes(String ip, int port) async {
    try {
      final apiService = _createApiService(ip, port);
      return await apiService
          .getPairCodes()
          .asStream()
          .map((event) => event)
          .first;
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
      return await apiService
          .pairDevice(body)
          .asStream()
          .map((event) => event)
          .first;
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
      return await apiService
          .getShopfronts(apiKey)
          .asStream()
          .map((event) => event)
          .first;
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
      return await apiService
          .connectShopfront(shopfrontId, apiKey)
          .asStream()
          .map((event) => event)
          .first;
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
      return await apiService
          .fetchShopfrontStocks(shopfrontId, apiKey, body)
          .asStream()
          .map((event) => event)
          .first;
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
      return await apiService
          .updateShopfrontStock(shopfrontId, apiKey, body)
          .asStream()
          .map((event) => event)
          .first;
    } on Exception catch (error) {
      logger.e('Error updating shopfront stock from network: $error');
      return Future.error(throwExceptionForAPIErrors(error));
    }
  }

  @override
  Future<CustomerLookupApiResponse> fetchShopfrontCustomers(
    String ip,
    int port,
    String shopfrontId,
    String apiKey,
    Map<String, dynamic> body,
  ) async {
    try {
      final apiService = _createApiService(ip, port);
      return await apiService
          .fetchShopfrontCustomers(shopfrontId, apiKey, body)
          .asStream()
          .map((event) => event)
          .first;
    } on Exception catch (error) {
      logger.e('Error fetching shopfront customers from network: $error');
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
      return await apiService
          .uploadShopfrontPicture(shopfrontId, stockId, apiKey, jpgBytes)
          .asStream()
          .map((event) => event)
          .first;
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
      return await apiService
          .stocktakeInitCheck(shopfrontId, apiKey, body)
          .asStream()
          .map((event) => event)
          .first;
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
      return await apiService
          .stocktakeCommit(shopfrontId, apiKey, body)
          .asStream()
          .map((event) => event)
          .first;
    } on Exception catch (error) {
      logger.e('Error calling stocktake commit from network: $error');
      return Future.error(throwExceptionForAPIErrors(error));
    }
  }

  @override
  Future<StocktakeBackupResponse> stocktakeBackup(
    String ip,
    int port,
    String shopfrontId,
    String apiKey,
    Map<String, dynamic> body,
  ) async {
    try {
      final apiService = _createApiService(ip, port);
      return await apiService
          .stocktakeBackup(shopfrontId, apiKey, body)
          .asStream()
          .map((event) => event)
          .first;
    } on Exception catch (error) {
      logger.e('Error backing up stocktake from network: $error');
      return Future.error(throwExceptionForAPIErrors(error));
    }
  }

  @override
  Future<BackupListResponse> getStocktakeBackupList(
    String ip,
    int port,
    String shopfrontId,
    String apiKey,
  ) async {
    try {
      final apiService = _createApiService(ip, port);
      return await apiService
          .getStocktakeBackupList(shopfrontId, apiKey)
          .asStream()
          .map((event) => event)
          .first;
    } on Exception catch (error) {
      logger.e('Error fetching backup list from network: $error');
      return Future.error(throwExceptionForAPIErrors(error));
    }
  }

  @override
  Future<LoadBackupResponse> loadStocktakeBackup(
    String ip,
    int port,
    String shopfrontId,
    String fileName,
    String apiKey,
  ) async {
    try {
      final apiService = _createApiService(ip, port);
      return await apiService
          .loadStocktakeBackup(shopfrontId, fileName, apiKey)
          .asStream()
          .map((event) => event)
          .first;
    } on Exception catch (error) {
      logger.e('Error loading backup from network: $error');
      return Future.error(throwExceptionForAPIErrors(error));
    }
  }

  @override
  Future<AuthenticateStaffResponse> authenticateStaff(
    String ip,
    int port,
    String shopfrontId,
    String apiKey,
    Map<String, dynamic> body,
  ) async {
    try {
      final apiService = _createApiService(ip, port);
      return await apiService
          .authenticateStaff(shopfrontId, apiKey, body)
          .asStream()
          .map((event) => event)
          .first;
    } on Exception catch (error) {
      logger.e('Error authenticating staff from network: $error');
      return Future.error(throwExceptionForAPIErrors(error));
    }
  }

  @override
  Future<SecurityGroupsResponse> getSecurityGroups(
    String ip,
    int port,
    String shopfrontId,
    String apiKey,
  ) async {
    try {
      final apiService = _createApiService(ip, port);
      return await apiService
          .getSecurityGroups(shopfrontId, apiKey)
          .asStream()
          .map((event) => event)
          .first;
    } on Exception catch (error) {
      logger.e('Error loading security groups from network: $error');
      return Future.error(throwExceptionForAPIErrors(error));
    }
  }

  @override
  Future<StocktakeLimitResponse> getStocktakeLimit(
    String ip,
    int port,
    String apiKey,
  ) async {
    try {
      final apiService = _createApiService(ip, port);
      return await apiService
          .getStocktakeLimit(apiKey)
          .asStream()
          .map((event) => event)
          .first;
    } on Exception catch (error) {
      logger.e('Error getting stocktake limit from network: $error');
      return Future.error(throwExceptionForAPIErrors(error));
    }
  }

  @override
  Future<ValidateResponse> validate(String ip, int port, String apiKey) async {
    try {
      final apiService = _createApiService(ip, port);
      return await apiService
          .validate(apiKey)
          .asStream()
          .map((event) => event)
          .first;
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
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: _connectTimeout,
        receiveTimeout: _receiveTimeout,
        sendTimeout: _sendTimeout,
      ),
    );
    dio.interceptors.add(
      _RetryInterceptor(
        dio: dio,
        maxRetries: 3,
        retryDelayMs: 3000,
        maxTotalRetryMs: 30000,
      ),
    );
    return ApiService(dio);
  }
}

class _RetryInterceptor extends Interceptor {
  _RetryInterceptor({
    required Dio dio,
    this.maxRetries = 3,
    this.retryDelayMs = 3000,
    this.maxTotalRetryMs = 30000,
  })
    : _dio = dio;

  final Dio _dio;
  final int maxRetries;
  final int retryDelayMs;
  final int maxTotalRetryMs;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra['retry_start_ms'] ??= DateTime.now().millisecondsSinceEpoch;
    options.extra['retry_attempt'] ??= 0;
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final options = err.requestOptions;
    final int attempt = (options.extra['retry_attempt'] as int?) ?? 0;
    final int retryStartMs =
        (options.extra['retry_start_ms'] as int?) ??
        DateTime.now().millisecondsSinceEpoch;
    final int elapsedMs = DateTime.now().millisecondsSinceEpoch - retryStartMs;

    if (attempt >= maxRetries ||
        elapsedMs >= maxTotalRetryMs ||
        !_shouldRetry(err)) {
      return handler.next(err);
    }

    final int nextAttempt = attempt + 1;
    options.extra['retry_attempt'] = nextAttempt;

    try {
      await Future<void>.delayed(Duration(milliseconds: retryDelayMs));
      final response = await _dio.fetch<dynamic>(options);
      return handler.resolve(response);
    } on DioException catch (e) {
      return handler.next(e);
    } catch (_) {
      return handler.next(err);
    }
  }

  bool _shouldRetry(DioException err) {
    if (err.type == DioExceptionType.cancel) return false;
    if (_isAlwaysRetryEndpoint(err.requestOptions.path)) return true;

    if (err.type == DioExceptionType.connectionError ||
        err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout) {
      return true;
    }

    final statusCode = err.response?.statusCode ?? 0;
    return statusCode >= 500 || statusCode == 408 || statusCode == 429;
  }

  bool _isAlwaysRetryEndpoint(String path) {
    final p = path.toLowerCase();

    // /shopfronts/{id}/stock
    if (RegExp(r'^/shopfronts/[^/]+/stock$').hasMatch(p)) return true;

    // /shopfronts/{id}/stock/update
    if (RegExp(r'^/shopfronts/[^/]+/stock/update$').hasMatch(p)) return true;

    // /shopfronts/{id}/pictures/{stockId}
    if (RegExp(r'^/shopfronts/[^/]+/pictures/[^/]+$').hasMatch(p)) return true;

    // /shopfronts/{id}/stocktake/initcheck
    if (RegExp(r'^/shopfronts/[^/]+/stocktake/initcheck$').hasMatch(p)) {
      return true;
    }

    // /shopfronts/{id}/stocktake/commit
    if (RegExp(r'^/shopfronts/[^/]+/stocktake/commit$').hasMatch(p)) {
      return true;
    }

    return false;
  }
}
