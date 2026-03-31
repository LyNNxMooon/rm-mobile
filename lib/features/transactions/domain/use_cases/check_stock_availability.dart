import '../../../../entities/vos/stock_vo.dart';

/// Result of checking if stock can be added to cart
class StockAvailabilityResult {
  final bool canAdd;
  final String? message;

  const StockAvailabilityResult({
    required this.canAdd,
    this.message,
  });

  /// Stock can be added
  const StockAvailabilityResult.allowed()
      : canAdd = true,
        message = null;

  /// Stock cannot be added - out of stock
  factory StockAvailabilityResult.notPermitted() {
    return const StockAvailabilityResult(
      canAdd: false,
      message: "Stock items cannot be sold if inventory levels are below the sale quantity.",
    );
  }
}

/// Use case for checking if a stock item can be added to cart
class CheckStockAvailability {
  CheckStockAvailability();

  /// Checks if stock can be added based on availability
  ///
  /// [stock] - The stock item being added to cart
  /// [saleQty] - The quantity being sold
  /// [preventAddIfNoStock] - Whether the setting is enabled
  ///
  /// Returns:
  /// - StockAvailabilityResult.notPermitted if setting enabled AND sale qty > stock qty
  /// - StockAvailabilityResult.allowed otherwise
  StockAvailabilityResult call({
    required StockVO stock,
    required double saleQty,
    required bool preventAddIfNoStock,
  }) {
    // If the setting is disabled, always allow
    if (!preventAddIfNoStock) {
      return const StockAvailabilityResult.allowed();
    }

    final num stockQty = stock.quantity;

    // Check if sale quantity exceeds available stock
    if (saleQty > stockQty) {
      return StockAvailabilityResult.notPermitted();
    }

    return const StockAvailabilityResult.allowed();
  }
}
