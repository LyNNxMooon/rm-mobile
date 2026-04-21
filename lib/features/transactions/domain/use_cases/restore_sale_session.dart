import '../../../../local_db/local_db_dao.dart';
import '../../../../entities/vos/cart_item_vo.dart';
import '../../../../entities/vos/customer_vo.dart';
import '../../../../entities/vos/stock_vo.dart';
import '../../../../entities/vos/sale_session_vo.dart';
import '../../../../utils/tax_calculation_utils.dart';

/// Result of restoring a sale session
class RestoreSessionResult {
  final List<CartItemVO> cartItems;
  final CustomerVO? customer;
  final int? staffId;
  final double discount;
  final double totalInc;
  final Map<String, double> paymentAmounts;
  final String surveyValue;
  final String commentValue;
  final String? drawer;
  final DeliveryAddressData? deliveryAddress;
  final EmailAuditData? emailAudit;

  RestoreSessionResult({
    required this.cartItems,
    this.customer,
    this.staffId,
    required this.discount,
    this.totalInc = 0.0,
    required this.paymentAmounts,
    required this.surveyValue,
    required this.commentValue,
    this.drawer,
    this.deliveryAddress,
    this.emailAudit,
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

      // Use saved tax values if available, otherwise calculate
      double incPrice = itemData.sellInc;
      double exPrice = itemData.sellEx;
      double taxPercentage = itemData.taxPercentage ?? 0.0;
      int taxType = itemData.taxType ?? 0;

      // If we don't have saved prices, try to calculate from stock
      if (incPrice == 0 && exPrice == 0 && stock != null) {
        if (stock.isPackage == true && stock.sellEx != null && stock.sellInc != null) {
          // For package items, use sell_ex/sell_inc directly from stock
          incPrice = stock.sellInc!;
          exPrice = stock.sellEx!;
          // Calculate percentage from prices
          taxPercentage = exPrice > 0 ? ((incPrice - exPrice) / exPrice) * 100 : 0.0;
          // Look up actual taxType from sales_tax (for GP calculation)
          final taxResult = await TaxCalculationUtils.calculateSellTax(
            sell: stock.sell,
            salesTax: stock.salesTax,
          );
          taxType = taxResult.taxType;
        } else {
          // Regular items - calculate using tax tables
          final taxResult = await TaxCalculationUtils.calculateSellTax(
            sell: stock.sell,
            salesTax: stock.salesTax,
          );
          incPrice = taxResult.incPrice;
          exPrice = taxResult.exPrice;
          taxPercentage = taxResult.percentage;
          taxType = taxResult.taxType;
        }
      }

      final cartItem = CartItemVO(
        code: itemData.code,
        description: itemData.description ?? stock?.description ?? itemData.code,
        qty: itemData.qty,
        sellPrice: incPrice, // Use inclusive price as sell price
        costPrice: itemData.costEx > 0 ? itemData.costEx : itemData.costInc,
        stock: stock,
        serialNumbers: itemData.serialNumbers,
        isEditing: false,
        isPriceOverridden: itemData.isPriceOverridden,
        taxPercentage: taxPercentage,
        taxType: taxType,
        incPrice: incPrice,
        exPrice: exPrice,
        computedCostEx: itemData.costEx,
        computedCostInc: itemData.costInc,
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
      staffId: session.staffId,
      discount: session.discount,
      totalInc: session.totalInc,
      paymentAmounts: Map.from(session.paymentAmounts),
      surveyValue: session.surveyValue ?? '',
      commentValue: session.commentValue ?? '',
      drawer: session.drawer,
      deliveryAddress: session.deliveryAddress,
      emailAudit: session.emailAudit,
    );
  }
}
