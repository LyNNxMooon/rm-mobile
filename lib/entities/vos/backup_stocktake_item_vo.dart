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
}
