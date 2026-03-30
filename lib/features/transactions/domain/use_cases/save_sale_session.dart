import '../../../../local_db/local_db_dao.dart';
import '../../../../entities/vos/cart_item_vo.dart';
import '../../../../entities/vos/customer_vo.dart';
import '../../../../entities/vos/sale_session_vo.dart';

/// Data class for session save parameters
class SaveSessionParams {
  final int? existingSessionId;
  final String sessionType;
  final String shopfront;
  final List<CartItemVO> cartItems;
  final CustomerVO? customer;
  final double subtotal;
  final double discount;
  final Map<String, double> paymentAmounts;
  final String? surveyValue;
  final String? commentValue;
  final String Function(CustomerVO) buildCustomerDisplayName;

  SaveSessionParams({
    this.existingSessionId,
    required this.sessionType,
    required this.shopfront,
    required this.cartItems,
    this.customer,
    required this.subtotal,
    required this.discount,
    required this.paymentAmounts,
    this.surveyValue,
    this.commentValue,
    required this.buildCustomerDisplayName,
  });
}

/// Use case for saving a sale session (create or update)
class SaveSaleSession {
  /// Save or update a sale session
  /// Returns the session ID (new ID if created, existing ID if updated)
  /// Returns null if cart is empty (session should be deleted instead)
  Future<int?> call(SaveSessionParams params) async {
    // Don't save if cart is empty
    if (params.cartItems.isEmpty) {
      return null;
    }

    if (params.shopfront.isEmpty) return null;

    final now = DateTime.now();
    final cartItemsData = params.cartItems
        .map((e) => CartItemData.fromCartItem(e))
        .toList();

    final sessionMap = <String, dynamic>{
      'session_type': params.sessionType,
      'shopfront': params.shopfront,
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
      'customer_id': params.customer?.customerId,
      'customer_barcode': params.customer?.barcode,
      'customer_name': params.customer != null
          ? params.buildCustomerDisplayName(params.customer!)
          : null,
      'subtotal': params.subtotal,
      'discount': params.discount,
      'survey_value': params.surveyValue?.isNotEmpty == true 
          ? params.surveyValue 
          : null,
      'comment_value': params.commentValue?.isNotEmpty == true 
          ? params.commentValue 
          : null,
    };

    // Properly encode cart items
    if (params.cartItems.isNotEmpty) {
      sessionMap['cart_items_json'] =
          '[${cartItemsData.map((e) => '{"code":"${e.code}","description":"${e.description.replaceAll('"', '\\"')}","qty":${e.qty},"sell_price":${e.sellPrice},"cost_price":${e.costPrice ?? 0},"serial_number":${e.serialNumber != null ? '"${e.serialNumber}"' : 'null'},"stock_id":${e.stockId ?? 'null'}}').join(',')}]';
    }

    // Properly encode payment amounts
    if (params.paymentAmounts.isNotEmpty) {
      sessionMap['payment_amounts_json'] =
          '{${params.paymentAmounts.entries.map((e) => '"${e.key}":${e.value}').join(',')}}';
    }

    if (params.existingSessionId != null) {
      sessionMap['id'] = params.existingSessionId;
      await LocalDbDAO.instance.updateSaleSession(sessionMap);
      return params.existingSessionId;
    } else {
      return await LocalDbDAO.instance.saveSaleSession(sessionMap);
    }
  }
}
