class PendingStockUpdateVO {
  final int id;
  final String shopfront;
  final int stockId;
  final Map<String, dynamic> payload;
  final String createdAt;

  PendingStockUpdateVO({
    required this.id,
    required this.shopfront,
    required this.stockId,
    required this.payload,
    required this.createdAt,
  });
}
