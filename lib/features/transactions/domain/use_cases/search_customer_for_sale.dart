import '../../../../entities/response/customer_search_response.dart';
import '../../../../utils/global_var_utils.dart';
import '../repositories/sales_repo.dart';

/// Use case for searching customer for sales transaction
class SearchCustomerForSale {
  final SalesRepo repository;

  SearchCustomerForSale(this.repository);

  /// Searches for customer by query (barcode → name → company → phone → email → address)
  /// Returns CustomerSearchResult with found customer, duplicates, or notFound
  Future<CustomerSearchResult> call(String query) {
    final String shopfront = AppGlobals.instance.shopfront ?? "";
    return repository.searchCustomerForSale(query, shopfront);
  }
}
