import '../../../../entities/response/stock_search_resposne.dart';
import '../../../../entities/response/customer_search_response.dart';
import '../../../../entities/response/invoice_response.dart';

/// Repository interface for sales/transaction operations
abstract class SalesRepo {
  /// Search for stock by query (barcode, description, custom1, custom2)
  Future<StockSearchResult> searchStockForSale(String query, String shopfront);

  /// Fetch the last sold price for a stock from the server and store it locally.
  /// Returns the last sold price, or null if the stock has never been sold.
  Future<double?> fetchAndStoreLastSoldPrice(int stockId, String shopfront);

  /// Read the locally stored (cached) last sold price for a stock.
  /// Returns null if no value has been stored yet.
  Future<double?> getStoredLastSoldPrice(int stockId, String shopfront);

  /// Search for customer by query (barcode, name, company, phone, email, address)
  Future<CustomerSearchResult> searchCustomerForSale(String query, String shopfront);

  /// Create account invoice
  Future<InvoiceResponse> createAccountInvoice(Map<String, dynamic> body);

  /// Create sales order
  Future<InvoiceResponse> createSalesOrder(Map<String, dynamic> body);

  /// Create quote
  Future<InvoiceResponse> createQuote(Map<String, dynamic> body);

  /// Create layby
  Future<InvoiceResponse> createLayby(Map<String, dynamic> body);

  /// Get cash drawer identifier for transactions
  Future<String?> getCashDrawerIdentifier();
}
