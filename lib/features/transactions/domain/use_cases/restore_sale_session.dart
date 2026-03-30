import '../../../../local_db/local_db_dao.dart';
import '../../../../entities/vos/cart_item_vo.dart';
import '../../../../entities/vos/customer_vo.dart';
import '../../../../entities/vos/stock_vo.dart';
import '../../../../entities/vos/sale_session_vo.dart';

/// Result of restoring a sale session
class RestoreSessionResult {
  final List<CartItemVO> cartItems;
  final CustomerVO? customer;
  final double discount;
  final Map<String, double> paymentAmounts;
  final String surveyValue;
  final String commentValue;

  RestoreSessionResult({
    required this.cartItems,
    this.customer,
    required this.discount,
    required this.paymentAmounts,
    required this.surveyValue,
    required this.commentValue,
  });
}

/// Use case for restoring a sale session's data (stocks and customer)
class RestoreSaleSession {
  /// Restore cart items with full stock data and customer from a saved session
  Future<RestoreSessionResult> call({
    required SaleSessionVO session,
    required String shopfront,
  }) async {
    final cartItems = <CartItemVO>[];

    // Restore cart items with full stock data
    for (final itemData in session.cartItems) {
      // Try to find stock from database for full data
      final stockSearch = await LocalDbDAO.instance.getStockBySearch(
        itemData.code,
        shopfront,
      );

      StockVO? stock;
      if (stockSearch.stock != null) {
        stock = stockSearch.stock;
      } else if (stockSearch.duplicates.isNotEmpty) {
        stock = stockSearch.duplicates.first;
      }

      final cartItem = CartItemVO(
        code: itemData.code,
        description: itemData.description,
        qty: itemData.qty,
        sellPrice: itemData.sellPrice,
        costPrice: itemData.costPrice,
        stock: stock,
        serialNumber: itemData.serialNumber,
        isEditing: false,
      );
      cartItems.add(cartItem);
    }

    // Restore customer (if we have customer barcode, try to look them up)
    CustomerVO? customer;
    if (session.customerId != null && session.customerBarcode != null) {
      final customerSearch = await LocalDbDAO.instance.getCustomerBySearch(
        session.customerBarcode!,
        shopfront,
      );
      if (customerSearch.customer != null) {
        customer = customerSearch.customer;
      }
    }

    return RestoreSessionResult(
      cartItems: cartItems,
      customer: customer,
      discount: session.discount,
      paymentAmounts: Map.from(session.paymentAmounts),
      surveyValue: session.surveyValue ?? '',
      commentValue: session.commentValue ?? '',
    );
  }
}
