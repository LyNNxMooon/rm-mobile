// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'customer_transactions_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CustomerTransactionsResponse _$CustomerTransactionsResponseFromJson(
        Map<String, dynamic> json) =>
    CustomerTransactionsResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
      shopfrontId: json['shopfrontId'] as String? ?? json['shopfront_id'] as String,
      shopfrontName: json['shopfrontName'] as String? ?? json['shopfront_name'] as String,
      customerId: (json['customerId'] as num? ?? json['customer_id'] as num).toInt(),
      transactionType: json['transactionType'] as String? ?? json['transaction_type'] as String?,
      syncTimestamp: json['syncTimestamp'] as String? ?? json['sync_timestamp'] as String,
      count: (json['count'] as num?)?.toInt(),
      hasMore: json['hasMore'] as bool? ?? json['has_more'] as bool?,
      nextCursor: (json['nextCursor'] as num? ?? json['next_cursor'] as num?)?.toInt(),
      data: CustomerTransactionsData.fromJson(
          json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$CustomerTransactionsResponseToJson(
        CustomerTransactionsResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'shopfrontId': instance.shopfrontId,
      'shopfrontName': instance.shopfrontName,
      'customerId': instance.customerId,
      'transactionType': instance.transactionType,
      'syncTimestamp': instance.syncTimestamp,
      'count': instance.count,
      'hasMore': instance.hasMore,
      'nextCursor': instance.nextCursor,
      'data': instance.data,
    };

CustomerTransactionsData _$CustomerTransactionsDataFromJson(
        Map<String, dynamic> json) =>
    CustomerTransactionsData(
      purchases: (json['purchases'] as List<dynamic>?)
          ?.map((e) => CustomerPurchaseItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      credit: (json['credit'] as List<dynamic>?)
          ?.map((e) => CustomerCreditItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      invoices: (json['invoices'] as List<dynamic>?)
          ?.map((e) => CustomerInvoiceItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      ivPay: (json['ivPay'] as List<dynamic>?)
          ?.map((e) => CustomerIvPayItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      laybys: (json['laybys'] as List<dynamic>?)
          ?.map((e) => CustomerLaybyItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      lbPay: (json['lbPay'] as List<dynamic>?)
          ?.map((e) => CustomerLbPayItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      cso: (json['cso'] as List<dynamic>?)
          ?.map((e) => CustomerCsoItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      soQuote: (json['soQuote'] as List<dynamic>?)
          ?.map((e) => CustomerSoQuoteItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      soPay: (json['soPay'] as List<dynamic>?)
          ?.map((e) => CustomerSoPayItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$CustomerTransactionsDataToJson(
        CustomerTransactionsData instance) =>
    <String, dynamic>{
      'purchases': instance.purchases,
      'credit': instance.credit,
      'invoices': instance.invoices,
      'ivPay': instance.ivPay,
      'laybys': instance.laybys,
      'lbPay': instance.lbPay,
      'cso': instance.cso,
      'soQuote': instance.soQuote,
      'soPay': instance.soPay,
    };

CustomerPurchaseItem _$CustomerPurchaseItemFromJson(
        Map<String, dynamic> json) =>
    CustomerPurchaseItem(
      id: (json['id'] as num).toInt(),
      docketId: (json['docketId'] as num? ?? json['docket_id'] as num).toInt(),
      date: json['date'] as String,
      product: json['product'] as String,
      qty: json['qty'] as num,
      price: json['price'] as num,
      priceInc: json['priceInc'] as num? ?? json['price_inc'] as num?,
      stockId: (json['stockId'] as num? ?? json['stock_id'] as num).toInt(),
      goodsTax: json['goodsTax'] as String? ?? json['goods_tax'] as String?,
    );

Map<String, dynamic> _$CustomerPurchaseItemToJson(
        CustomerPurchaseItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'docketId': instance.docketId,
      'date': instance.date,
      'product': instance.product,
      'qty': instance.qty,
      'price': instance.price,
      'priceInc': instance.priceInc,
      'stockId': instance.stockId,
      'goodsTax': instance.goodsTax,
    };

CustomerCreditItem _$CustomerCreditItemFromJson(Map<String, dynamic> json) =>
    CustomerCreditItem(
      id: (json['id'] as num).toInt(),
      date: json['date'] as String,
      creditId: (json['creditId'] as num? ?? json['credit_id'] as num).toInt(),
      source: (json['source'] as num).toInt(),
      creditType: json['creditType'] as String? ?? json['credit_type'] as String,
      amount: json['amount'] as num,
    );

Map<String, dynamic> _$CustomerCreditItemToJson(CustomerCreditItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'date': instance.date,
      'creditId': instance.creditId,
      'source': instance.source,
      'creditType': instance.creditType,
      'amount': instance.amount,
    };

CustomerInvoiceItem _$CustomerInvoiceItemFromJson(Map<String, dynamic> json) =>
    CustomerInvoiceItem(
      id: (json['id'] as num).toInt(),
      date: json['date'] as String,
      invoiceNo: (json['invoiceNo'] as num? ?? json['invoice_no'] as num).toInt(),
      invTotal: json['invTotal'] as num? ?? json['inv_total'] as num,
      amountOwing: json['amountOwing'] as num? ?? json['amount_owing'] as num,
    );

Map<String, dynamic> _$CustomerInvoiceItemToJson(
        CustomerInvoiceItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'date': instance.date,
      'invoiceNo': instance.invoiceNo,
      'invTotal': instance.invTotal,
      'amountOwing': instance.amountOwing,
    };

CustomerIvPayItem _$CustomerIvPayItemFromJson(Map<String, dynamic> json) =>
    CustomerIvPayItem(
      id: (json['id'] as num).toInt(),
      date: json['date'] as String,
      invoiceNo: (json['invoiceNo'] as num? ?? json['invoice_no'] as num).toInt(),
      paymentNo: (json['paymentNo'] as num? ?? json['payment_no'] as num).toInt(),
      trn: json['trn'] as String,
      discount: json['discount'] as num,
      amountPaid: json['amountPaid'] as num? ?? json['amount_paid'] as num,
    );

Map<String, dynamic> _$CustomerIvPayItemToJson(
        CustomerIvPayItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'date': instance.date,
      'invoiceNo': instance.invoiceNo,
      'paymentNo': instance.paymentNo,
      'trn': instance.trn,
      'discount': instance.discount,
      'amountPaid': instance.amountPaid,
    };

CustomerLaybyItem _$CustomerLaybyItemFromJson(Map<String, dynamic> json) =>
    CustomerLaybyItem(
      id: (json['id'] as num).toInt(),
      date: json['date'] as String,
      laybyNo: (json['laybyNo'] as num? ?? json['layby_no'] as num).toInt(),
      lastPayment: json['lastPayment'] as String? ?? json['last_payment'] as String?,
      total: json['total'] as num,
      amountOwing: json['amountOwing'] as num? ?? json['amount_owing'] as num,
    );

Map<String, dynamic> _$CustomerLaybyItemToJson(CustomerLaybyItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'date': instance.date,
      'laybyNo': instance.laybyNo,
      'lastPayment': instance.lastPayment,
      'total': instance.total,
      'amountOwing': instance.amountOwing,
    };

CustomerLbPayItem _$CustomerLbPayItemFromJson(Map<String, dynamic> json) =>
    CustomerLbPayItem(
      id: (json['id'] as num).toInt(),
      date: json['date'] as String,
      laybyNo: (json['laybyNo'] as num? ?? json['layby_no'] as num).toInt(),
      paymentNo: (json['paymentNo'] as num? ?? json['payment_no'] as num).toInt(),
      amountPaid: json['amountPaid'] as num? ?? json['amount_paid'] as num,
      paymentType: json['paymentType'] as String? ?? json['payment_type'] as String,
    );

Map<String, dynamic> _$CustomerLbPayItemToJson(CustomerLbPayItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'date': instance.date,
      'laybyNo': instance.laybyNo,
      'paymentNo': instance.paymentNo,
      'amountPaid': instance.amountPaid,
      'paymentType': instance.paymentType,
    };

CustomerCsoItem _$CustomerCsoItemFromJson(Map<String, dynamic> json) =>
    CustomerCsoItem(
      id: (json['id'] as num).toInt(),
      date: json['date'] as String,
      product: json['product'] as String,
      sell: json['sell'] as num,
      qty: json['qty'] as num,
      status: json['status'] as String,
      stockId: (json['stockId'] as num? ?? json['stock_id'] as num?)?.toInt(),
    );

Map<String, dynamic> _$CustomerCsoItemToJson(CustomerCsoItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'date': instance.date,
      'product': instance.product,
      'sell': instance.sell,
      'qty': instance.qty,
      'status': instance.status,
      'stockId': instance.stockId,
    };

CustomerSoQuoteItem _$CustomerSoQuoteItemFromJson(Map<String, dynamic> json) =>
    CustomerSoQuoteItem(
      id: (json['id'] as num).toInt(),
      date: json['date'] as String,
      salesorderNo: (json['salesorderNo'] as num? ?? json['salesorder_no'] as num).toInt(),
      type: json['type'] as String,
      status: json['status'] as String,
      total: json['total'] as num,
      owing: json['owing'] as num,
    );

Map<String, dynamic> _$CustomerSoQuoteItemToJson(
        CustomerSoQuoteItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'date': instance.date,
      'salesorderNo': instance.salesorderNo,
      'type': instance.type,
      'status': instance.status,
      'total': instance.total,
      'owing': instance.owing,
    };

CustomerSoPayItem _$CustomerSoPayItemFromJson(Map<String, dynamic> json) =>
    CustomerSoPayItem(
      id: (json['id'] as num).toInt(),
      date: json['date'] as String,
      salesorderNo: (json['salesorderNo'] as num? ?? json['salesorder_no'] as num).toInt(),
      paymentNo: (json['paymentNo'] as num? ?? json['payment_no'] as num).toInt(),
      amountPaid: json['amountPaid'] as num? ?? json['amount_paid'] as num,
      paymentType: json['paymentType'] as String? ?? json['payment_type'] as String,
    );

Map<String, dynamic> _$CustomerSoPayItemToJson(CustomerSoPayItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'date': instance.date,
      'salesorderNo': instance.salesorderNo,
      'paymentNo': instance.paymentNo,
      'amountPaid': instance.amountPaid,
      'paymentType': instance.paymentType,
    };
