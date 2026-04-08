import 'dart:convert';

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
  final int? staffId;
  final double subtotal;
  final double discount;
  final double totalInc;
  final double totalEx;
  final Map<String, double> paymentAmounts;
  final String? surveyValue;
  final String? commentValue;
  final String? drawer;
  final DeliveryAddressData? deliveryAddress;
  final EmailAuditData? emailAudit;
  final String Function(CustomerVO) buildCustomerDisplayName;

  SaveSessionParams({
    this.existingSessionId,
    required this.sessionType,
    required this.shopfront,
    required this.cartItems,
    this.customer,
    this.staffId,
    required this.subtotal,
    required this.discount,
    this.totalInc = 0.0,
    this.totalEx = 0.0,
    required this.paymentAmounts,
    this.surveyValue,
    this.commentValue,
    this.drawer,
    this.deliveryAddress,
    this.emailAudit,
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
    final cartItemsData = await Future.wait(
      params.cartItems.map((e) => CartItemData.fromCartItemAsync(e, shopfront: params.shopfront)),
    );

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
      'staff_id': params.staffId,
      'subtotal': params.subtotal,
      'discount': params.discount,
      'total_inc': params.totalInc,
      'total_ex': params.totalEx,
      'survey_value': params.surveyValue?.isNotEmpty == true 
          ? params.surveyValue 
          : null,
      'comment_value': params.commentValue?.isNotEmpty == true 
          ? params.commentValue 
          : null,
      'drawer': params.drawer,
    };

    // Encode cart items as JSON (includes package items with isPackage=true)
    if (params.cartItems.isNotEmpty) {
      sessionMap['cart_items_json'] = jsonEncode(
        cartItemsData.map((e) => e.toJson()).toList(),
      );
    }

    // Encode payment amounts as JSON
    if (params.paymentAmounts.isNotEmpty) {
      sessionMap['payment_amounts_json'] = jsonEncode(params.paymentAmounts);
    }

    // Encode delivery address as JSON (only when committed)
    if (params.deliveryAddress != null) {
      sessionMap['delivery_address_json'] = jsonEncode(
        params.deliveryAddress!.toJson(),
      );
    }

    // Encode email audit as JSON (only when "Email & Commit")
    if (params.emailAudit != null) {
      sessionMap['email_audit_json'] = jsonEncode(
        params.emailAudit!.toJson(),
      );
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
