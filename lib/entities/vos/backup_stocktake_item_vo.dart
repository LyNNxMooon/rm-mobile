class BackupStocktakeItemVO {
  final int stockId;
  final num quantity;
  final DateTime stocktakeDate;
  final DateTime dateModified;

  BackupStocktakeItemVO({
    required this.stockId,
    required this.quantity,
    required this.stocktakeDate,
    required this.dateModified,
  });

  factory BackupStocktakeItemVO.fromJson(Map<String, dynamic> json) {
    return BackupStocktakeItemVO(
      stockId: (json['stock_id'] as num).toInt(),
      quantity: json['quantity'] as num,
      stocktakeDate: DateTime.parse(json['stocktake_date'].toString()),
      dateModified: DateTime.parse(json['date_modified'].toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stock_id': stockId,
      'quantity': quantity,
      'stocktake_date': stocktakeDate.toIso8601String(),
      'date_modified': dateModified.toIso8601String(),
    };
  }
}
