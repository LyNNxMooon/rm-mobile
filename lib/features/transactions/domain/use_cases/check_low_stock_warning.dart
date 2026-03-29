import '../../../../entities/vos/stock_vo.dart';
import '../models/low_stock_warning.dart';

/// Use case for checking if a stock item needs a low stock warning
class CheckLowStockWarning {
  CheckLowStockWarning();

  /// Checks stock levels and returns appropriate warning
  ///
  /// [stock] - The stock item being added to cart
  /// [saleQty] - The quantity being sold
  /// [autoRemindEnabled] - Whether the Auto Remind - Low Stock setting is enabled
  ///
  /// Logic:
  /// 1. First check if order limits are set (either orderThreshold OR orderQuantity > 0)
  /// 2. If order limits set AND stock qty <= orderThreshold → "Time to reorder this stock item"
  /// 3. Only if no order limits set OR stock qty > orderThreshold:
  ///    If sale qty > stock qty → "Warning! inventory level is below sale quantity"
  LowStockWarning call({
    required StockVO stock,
    required int saleQty,
    required bool autoRemindEnabled,
  }) {
    // If the setting is disabled, return no warning
    if (!autoRemindEnabled) {
      return const LowStockWarning.none();
    }

    final num stockQty = stock.quantity;
    final num orderThreshold = stock.orderThreshold;
    final num orderQuantity = stock.orderQuantity;

    // Check if either orderThreshold OR orderQuantity has a value (non-zero)
    // If even one has a value, order limits are considered set
    final bool hasOrderLimitsSet = orderThreshold > 0 || orderQuantity > 0;

    if (hasOrderLimitsSet) {
      // Order limits are set - check stock qty against orderThreshold
      if (stockQty <= orderThreshold) {
        // Stock is at or below the reorder threshold
        return LowStockWarning.belowThreshold();
      }
      // Stock is above threshold, continue to check sale qty vs stock qty
    }

    // Case 2: Either no order limits set OR stock is above threshold
    // Check if sale quantity exceeds available stock
    if (saleQty > stockQty) {
      return LowStockWarning.saleExceedsStock();
    }

    return const LowStockWarning.none();
  }
}
