import 'package:json_annotation/json_annotation.dart';

part 'customer_transactions_response.g.dart';

@JsonSerializable()
class CustomerTransactionsResponse {
  final bool success;
  final String message;
  final String shopfrontId;
  final String shopfrontName;
  final int customerId;
  final String syncTimestamp;
  final CustomerTransactionsData data;

  CustomerTransactionsResponse({
    required this.success,
    required this.message,
    required this.shopfrontId,
    required this.shopfrontName,
    required this.customerId,
    required this.syncTimestamp,
    required this.data,
  });

  factory CustomerTransactionsResponse.fromJson(Map<String, dynamic> json) =>
      _$CustomerTransactionsResponseFromJson(json);
}

@JsonSerializable()
class CustomerTransactionsData {
  final List<CustomerPurchaseItem> purchases;
  final List<CustomerCreditItem> credit;
  final List<CustomerInvoiceItem> invoices;
  final List<CustomerIvPayItem> ivPay;
  final List<CustomerLaybyItem> laybys;
  final List<CustomerLbPayItem> lbPay;
  final List<CustomerCsoItem> cso;
  final List<CustomerSoQuoteItem> soQuote;
  final List<CustomerSoPayItem> soPay;

  CustomerTransactionsData({
    required this.purchases,
    required this.credit,
    required this.invoices,
    required this.ivPay,
    required this.laybys,
    required this.lbPay,
    required this.cso,
    required this.soQuote,
    required this.soPay,
  });

  factory CustomerTransactionsData.fromJson(Map<String, dynamic> json) =>
      _$CustomerTransactionsDataFromJson(json);
}

@JsonSerializable()
class CustomerPurchaseItem {
  final String date;
  final String product;
  final num qty;
  final num price;
  final int stockId;
  final String goodsTax;

  CustomerPurchaseItem({
    required this.date,
    required this.product,
    required this.qty,
    required this.price,
    required this.stockId,
    required this.goodsTax,
  });

  factory CustomerPurchaseItem.fromJson(Map<String, dynamic> json) =>
      _$CustomerPurchaseItemFromJson(json);
}

@JsonSerializable()
class CustomerCreditItem {
  final String date;
  final int creditId;
  final int source;
  final String creditType;
  final num amount;

  CustomerCreditItem({
    required this.date,
    required this.creditId,
    required this.source,
    required this.creditType,
    required this.amount,
  });

  factory CustomerCreditItem.fromJson(Map<String, dynamic> json) =>
      _$CustomerCreditItemFromJson(json);
}

@JsonSerializable()
class CustomerInvoiceItem {
  final String date;
  final int invoiceNo;
  final num invTotal;
  final num amountOwing;

  CustomerInvoiceItem({
    required this.date,
    required this.invoiceNo,
    required this.invTotal,
    required this.amountOwing,
  });

  factory CustomerInvoiceItem.fromJson(Map<String, dynamic> json) =>
      _$CustomerInvoiceItemFromJson(json);
}

@JsonSerializable()
class CustomerIvPayItem {
  final String date;
  final int invoiceNo;
  final int paymentNo;
  final String trn;
  final num discount;
  final num amountPaid;

  CustomerIvPayItem({
    required this.date,
    required this.invoiceNo,
    required this.paymentNo,
    required this.trn,
    required this.discount,
    required this.amountPaid,
  });

  factory CustomerIvPayItem.fromJson(Map<String, dynamic> json) =>
      _$CustomerIvPayItemFromJson(json);
}

@JsonSerializable()
class CustomerLaybyItem {
  final String date;
  final int laybyNo;
  final String lastPayment;
  final num total;
  final num amountOwing;

  CustomerLaybyItem({
    required this.date,
    required this.laybyNo,
    required this.lastPayment,
    required this.total,
    required this.amountOwing,
  });

  factory CustomerLaybyItem.fromJson(Map<String, dynamic> json) =>
      _$CustomerLaybyItemFromJson(json);
}

@JsonSerializable()
class CustomerLbPayItem {
  final String date;
  final int laybyNo;
  final int paymentNo;
  final num amountPaid;
  final String paymentType;

  CustomerLbPayItem({
    required this.date,
    required this.laybyNo,
    required this.paymentNo,
    required this.amountPaid,
    required this.paymentType,
  });

  factory CustomerLbPayItem.fromJson(Map<String, dynamic> json) =>
      _$CustomerLbPayItemFromJson(json);
}

@JsonSerializable()
class CustomerCsoItem {
  final String date;
  final String product;
  final num sell;
  final num qty;
  final String status;

  CustomerCsoItem({
    required this.date,
    required this.product,
    required this.sell,
    required this.qty,
    required this.status,
  });

  factory CustomerCsoItem.fromJson(Map<String, dynamic> json) =>
      _$CustomerCsoItemFromJson(json);
}

@JsonSerializable()
class CustomerSoQuoteItem {
  final String date;
  final int salesOrderNo;
  final String type;
  final String status;
  final num total;
  final num owing;

  CustomerSoQuoteItem({
    required this.date,
    required this.salesOrderNo,
    required this.type,
    required this.status,
    required this.total,
    required this.owing,
  });

  factory CustomerSoQuoteItem.fromJson(Map<String, dynamic> json) =>
      _$CustomerSoQuoteItemFromJson(json);
}

@JsonSerializable()
class CustomerSoPayItem {
  final String date;
  final int salesOrderNo;
  final int paymentNo;
  final num amountPaid;
  final String paymentType;

  CustomerSoPayItem({
    required this.date,
    required this.salesOrderNo,
    required this.paymentNo,
    required this.amountPaid,
    required this.paymentType,
  });

  factory CustomerSoPayItem.fromJson(Map<String, dynamic> json) =>
      _$CustomerSoPayItemFromJson(json);
}
