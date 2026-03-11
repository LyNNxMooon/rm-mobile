import 'package:flutter/material.dart';

class TransactionTypeHelper {
  static String translate(String code) {
    switch (code) {
      case "IV":
        return "Invoice";
      case "SA":
        return "Sale";
      case "LB":
        return "Lay-by";
      case "SO":
        return "Sales Order";
      case "QU":
        return "Quote";
      case "CS":
        return "Special Order";
      case "GR":
        return "Goods Received";
      case "RG":
        return "Returned Goods";
      case "PO":
        return "Purchase Order";
      case "ST":
        return "Stocktake";
      case "SL":
        return "Partial Stocktake";
      case "SI":
        return "Single Stocktake";
      case "MR":
        return "Merge";
      case "VC":
        return "Cost Change";
      case "VS":
        return "Sell Price Change";
      case "IP":
        return "Invoice Payment";
      case "LP":
        return "Lay-by Payment";
      case "SP":
        return "Sales Order Payment";
      case "LC":
        return "Lay-by Conversion";
      case "SC":
        return "Sales Order Conversion";
      default:
        return code;
    }
  }

  static IconData getIcon(String code) {
    if (["SA", "IV", "LB"].contains(code)) return Icons.shopping_cart_outlined;
    if (["GR", "PO"].contains(code)) return Icons.inventory_2_outlined;
    if (["RG"].contains(code)) return Icons.assignment_return_outlined;
    if (["ST", "SL", "SI"].contains(code)) return Icons.fact_check_outlined;
    return Icons.receipt_long_outlined;
  }
}
