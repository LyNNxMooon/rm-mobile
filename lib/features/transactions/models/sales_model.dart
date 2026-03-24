import 'package:rmstock_scanner/entities/response/stock_search_resposne.dart';
import 'package:rmstock_scanner/entities/response/customer_search_response.dart';
import 'package:rmstock_scanner/local_db/local_db_dao.dart';

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
}
