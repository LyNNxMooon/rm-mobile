import 'package:rmmobile/entities/response/stock_search_resposne.dart';
import 'package:rmmobile/entities/response/customer_search_response.dart';
import 'package:rmmobile/entities/response/invoice_response.dart';
import 'package:rmmobile/local_db/local_db_dao.dart';
import 'package:rmmobile/network/data_agent/data_agent_impl.dart';

import '../domain/repositories/sales_repo.dart';

/// Sales model - data manipulation layer
/// Implements SalesRepo and handles data operations via LocalDbDAO
class SalesModel implements SalesRepo {
  @override
  Future<StockSearchResult> searchStockForSale(
    String query,
    String shopfront,
  ) async {
    try {
      return await LocalDbDAO.instance.getStockBySearch(query, shopfront);
    } catch (error) {
      return Future.error(error);
    }
  }

  @override
  Future<CustomerSearchResult> searchCustomerForSale(
    String query,
    String shopfront,
  ) async {
    try {
      return await LocalDbDAO.instance.getCustomerBySearch(query, shopfront);
    } catch (error) {
      return Future.error(error);
    }
  }

  @override
  Future<InvoiceResponse> createAccountInvoice(Map<String, dynamic> body) async {
    try {
      final String resolvedIp =
          (await LocalDbDAO.instance.getHostIpAddress() ?? '').trim();
      final int resolvedPort =
          int.tryParse((await LocalDbDAO.instance.getHostPort() ?? '').trim()) ??
          5000;
      final String resolvedApiKey =
          (await LocalDbDAO.instance.getApiKey() ?? '').trim();
      final String resolvedShopfrontId =
          (await LocalDbDAO.instance.getShopfrontId() ?? '').trim();

      if (resolvedIp.isEmpty ||
          resolvedApiKey.isEmpty ||
          resolvedShopfrontId.isEmpty) {
        return Future.error(
          "Missing host/shopfront setup. Please reconnect to a host and shopfront.",
        );
      }

      return await DataAgentImpl.instance.createInvoice(
        resolvedIp,
        resolvedPort,
        resolvedShopfrontId,
        resolvedApiKey,
        body,
      );
    } catch (error) {
      return Future.error(error);
    }
  }

  @override
  Future<InvoiceResponse> createSalesOrder(Map<String, dynamic> body) async {
    try {
      final String resolvedIp =
          (await LocalDbDAO.instance.getHostIpAddress() ?? '').trim();
      final int resolvedPort =
          int.tryParse((await LocalDbDAO.instance.getHostPort() ?? '').trim()) ??
          5000;
      final String resolvedApiKey =
          (await LocalDbDAO.instance.getApiKey() ?? '').trim();
      final String resolvedShopfrontId =
          (await LocalDbDAO.instance.getShopfrontId() ?? '').trim();

      if (resolvedIp.isEmpty ||
          resolvedApiKey.isEmpty ||
          resolvedShopfrontId.isEmpty) {
        return Future.error(
          "Missing host/shopfront setup. Please reconnect to a host and shopfront.",
        );
      }

      return await DataAgentImpl.instance.createSalesOrder(
        resolvedIp,
        resolvedPort,
        resolvedShopfrontId,
        resolvedApiKey,
        body,
      );
    } catch (error) {
      return Future.error(error);
    }
  }

  @override
  Future<InvoiceResponse> createQuote(Map<String, dynamic> body) async {
    try {
      final String resolvedIp =
          (await LocalDbDAO.instance.getHostIpAddress() ?? '').trim();
      final int resolvedPort =
          int.tryParse((await LocalDbDAO.instance.getHostPort() ?? '').trim()) ??
          5000;
      final String resolvedApiKey =
          (await LocalDbDAO.instance.getApiKey() ?? '').trim();
      final String resolvedShopfrontId =
          (await LocalDbDAO.instance.getShopfrontId() ?? '').trim();

      if (resolvedIp.isEmpty ||
          resolvedApiKey.isEmpty ||
          resolvedShopfrontId.isEmpty) {
        return Future.error(
          "Missing host/shopfront setup. Please reconnect to a host and shopfront.",
        );
      }

      return await DataAgentImpl.instance.createQuote(
        resolvedIp,
        resolvedPort,
        resolvedShopfrontId,
        resolvedApiKey,
        body,
      );
    } catch (error) {
      return Future.error(error);
    }
  }

  @override
  Future<InvoiceResponse> createLayby(Map<String, dynamic> body) async {
    try {
      final String resolvedIp =
          (await LocalDbDAO.instance.getHostIpAddress() ?? '').trim();
      final int resolvedPort =
          int.tryParse((await LocalDbDAO.instance.getHostPort() ?? '').trim()) ??
          5000;
      final String resolvedApiKey =
          (await LocalDbDAO.instance.getApiKey() ?? '').trim();
      final String resolvedShopfrontId =
          (await LocalDbDAO.instance.getShopfrontId() ?? '').trim();

      if (resolvedIp.isEmpty ||
          resolvedApiKey.isEmpty ||
          resolvedShopfrontId.isEmpty) {
        return Future.error(
          "Missing host/shopfront setup. Please reconnect to a host and shopfront.",
        );
      }

      return await DataAgentImpl.instance.createLayby(
        resolvedIp,
        resolvedPort,
        resolvedShopfrontId,
        resolvedApiKey,
        body,
      );
    } catch (error) {
      return Future.error(error);
    }
  }
}
