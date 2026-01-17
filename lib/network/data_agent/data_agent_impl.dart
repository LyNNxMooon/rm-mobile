import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:rmstock_scanner/network/api/api_service.dart';
import 'package:rmstock_scanner/network/data_agent/data_agent.dart';
import '../../entities/response/error_response.dart';

class DataAgentImpl implements DataAgent {
  late ApiService _apiService;

  DataAgentImpl._() {
    _apiService = ApiService(Dio());
  }

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
}
