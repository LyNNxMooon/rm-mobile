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
      shopfrontId: json['shopfrontId'] as String,
      shopfrontName: json['shopfrontName'] as String,
      customerId: (json['customerId'] as num).toInt(),
      syncTimestamp: json['syncTimestamp'] as String,
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
      'syncTimestamp': instance.syncTimestamp,
      'data': instance.data,
    };

CustomerTransactionsData _$CustomerTransactionsDataFromJson(
        Map<String, dynamic> json) =>
    CustomerTransactionsData(
      purchases: (json['purchases'] as List<dynamic>)
          .map((e) => CustomerPurchaseItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      credit: (json['credit'] as List<dynamic>)
          .map((e) => CustomerCreditItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      invoices: (json['invoices'] as List<dynamic>)
          .map((e) => CustomerInvoiceItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      ivPay: (json['ivPay'] as List<dynamic>)
          .map((e) => CustomerIvPayItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      laybys: (json['laybys'] as List<dynamic>)
          .map((e) => CustomerLaybyItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      lbPay: (json['lbPay'] as List<dynamic>)
          .map((e) => CustomerLbPayItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      cso: (json['cso'] as List<dynamic>)
          .map((e) => CustomerCsoItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      soQuote: (json['soQuote'] as List<dynamic>)
          .map((e) => CustomerSoQuoteItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      soPay: (json['soPay'] as List<dynamic>)
          .map((e) => CustomerSoPayItem.fromJson(e as Map<String, dynamic>))
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
      date: json['date'] as String,
      product: json['product'] as String,
      qty: json['qty'] as num,
      price: json['price'] as num,
      stockId: (json['stockId'] as num).toInt(),
      goodsTax: json['goodsTax'] as String,
    );

Map<String, dynamic> _$CustomerPurchaseItemToJson(
        CustomerPurchaseItem instance) =>
    <String, dynamic>{
      'date': instance.date,
      'product': instance.product,
      'qty': instance.qty,
      'price': instance.price,
      'stockId': instance.stockId,
      'goodsTax': instance.goodsTax,
    };

CustomerCreditItem _$CustomerCreditItemFromJson(Map<String, dynamic> json) =>
    CustomerCreditItem(
      date: json['date'] as String,
      creditId: (json['creditId'] as num).toInt(),
      source: (json['source'] as num).toInt(),
      creditType: json['creditType'] as String,
      amount: json['amount'] as num,
    );

Map<String, dynamic> _$CustomerCreditItemToJson(CustomerCreditItem instance) =>
    <String, dynamic>{
      'date': instance.date,
      'creditId': instance.creditId,
      'source': instance.source,
      'creditType': instance.creditType,
      'amount': instance.amount,
    };

CustomerInvoiceItem _$CustomerInvoiceItemFromJson(Map<String, dynamic> json) =>
    CustomerInvoiceItem(
      date: json['date'] as String,
      invoiceNo: (json['invoiceNo'] as num).toInt(),
      invTotal: json['invTotal'] as num,
      amountOwing: json['amountOwing'] as num,
    );

Map<String, dynamic> _$CustomerInvoiceItemToJson(
        CustomerInvoiceItem instance) =>
    <String, dynamic>{
      'date': instance.date,
      'invoiceNo': instance.invoiceNo,
      'invTotal': instance.invTotal,
      'amountOwing': instance.amountOwing,
    };

CustomerIvPayItem _$CustomerIvPayItemFromJson(Map<String, dynamic> json) =>
    CustomerIvPayItem(
      date: json['date'] as String,
      invoiceNo: (json['invoiceNo'] as num).toInt(),
      paymentNo: (json['paymentNo'] as num).toInt(),
      trn: json['trn'] as String,
      discount: json['discount'] as num,
      amountPaid: json['amountPaid'] as num,
    );

Map<String, dynamic> _$CustomerIvPayItemToJson(
        CustomerIvPayItem instance) =>
    <String, dynamic>{
      'date': instance.date,
      'invoiceNo': instance.invoiceNo,
      'paymentNo': instance.paymentNo,
      'trn': instance.trn,
      'discount': instance.discount,
      'amountPaid': instance.amountPaid,
    };

CustomerLaybyItem _$CustomerLaybyItemFromJson(Map<String, dynamic> json) =>
    CustomerLaybyItem(
      date: json['date'] as String,
      laybyNo: (json['laybyNo'] as num).toInt(),
      lastPayment: json['lastPayment'] as String,
      total: json['total'] as num,
      amountOwing: json['amountOwing'] as num,
    );

Map<String, dynamic> _$CustomerLaybyItemToJson(CustomerLaybyItem instance) =>
    <String, dynamic>{
      'date': instance.date,
      'laybyNo': instance.laybyNo,
      'lastPayment': instance.lastPayment,
      'total': instance.total,
      'amountOwing': instance.amountOwing,
    };

CustomerLbPayItem _$CustomerLbPayItemFromJson(Map<String, dynamic> json) =>
    CustomerLbPayItem(
      date: json['date'] as String,
      laybyNo: (json['laybyNo'] as num).toInt(),
      paymentNo: (json['paymentNo'] as num).toInt(),
      amountPaid: json['amountPaid'] as num,
      paymentType: json['paymentType'] as String,
    );

Map<String, dynamic> _$CustomerLbPayItemToJson(CustomerLbPayItem instance) =>
    <String, dynamic>{
      'date': instance.date,
      'laybyNo': instance.laybyNo,
      'paymentNo': instance.paymentNo,
      'amountPaid': instance.amountPaid,
      'paymentType': instance.paymentType,
    };

CustomerCsoItem _$CustomerCsoItemFromJson(Map<String, dynamic> json) =>
    CustomerCsoItem(
      date: json['date'] as String,
      product: json['product'] as String,
      sell: json['sell'] as num,
      qty: json['qty'] as num,
      status: json['status'] as String,
    );

Map<String, dynamic> _$CustomerCsoItemToJson(CustomerCsoItem instance) =>
    <String, dynamic>{
      'date': instance.date,
      'product': instance.product,
      'sell': instance.sell,
      'qty': instance.qty,
      'status': instance.status,
    };

CustomerSoQuoteItem _$CustomerSoQuoteItemFromJson(Map<String, dynamic> json) =>
    CustomerSoQuoteItem(
      date: json['date'] as String,
      salesOrderNo: (json['salesOrderNo'] as num).toInt(),
      type: json['type'] as String,
      status: json['status'] as String,
      total: json['total'] as num,
      owing: json['owing'] as num,
    );

Map<String, dynamic> _$CustomerSoQuoteItemToJson(
        CustomerSoQuoteItem instance) =>
    <String, dynamic>{
      'date': instance.date,
      'salesOrderNo': instance.salesOrderNo,
      'type': instance.type,
      'status': instance.status,
      'total': instance.total,
      'owing': instance.owing,
    };

CustomerSoPayItem _$CustomerSoPayItemFromJson(Map<String, dynamic> json) =>
    CustomerSoPayItem(
      date: json['date'] as String,
      salesOrderNo: (json['salesOrderNo'] as num).toInt(),
      paymentNo: (json['paymentNo'] as num).toInt(),
      amountPaid: json['amountPaid'] as num,
      paymentType: json['paymentType'] as String,
    );

Map<String, dynamic> _$CustomerSoPayItemToJson(CustomerSoPayItem instance) =>
    <String, dynamic>{
      'date': instance.date,
      'salesOrderNo': instance.salesOrderNo,
      'paymentNo': instance.paymentNo,
      'amountPaid': instance.amountPaid,
      'paymentType': instance.paymentType,
    };
