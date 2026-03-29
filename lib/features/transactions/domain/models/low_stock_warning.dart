/// Represents the type of low stock warning to display
enum LowStockWarningType {
  /// Stock quantity is below order threshold - time to reorder
  belowThreshold,

  /// Sale quantity exceeds available stock
  saleExceedsStock,

  /// No warning needed
  none,
}

/// Result of checking low stock warning
class LowStockWarning {
  final LowStockWarningType type;
  final String? message;

  const LowStockWarning({
    required this.type,
    this.message,
  });

  /// No warning
  const LowStockWarning.none()
      : type = LowStockWarningType.none,
        message = null;

  /// Stock is below order threshold
  factory LowStockWarning.belowThreshold() {
    return const LowStockWarning(
      type: LowStockWarningType.belowThreshold,
      message: 'Time to reorder this stock item',
    );
  }

  /// Sale quantity exceeds available stock
  factory LowStockWarning.saleExceedsStock() {
    return const LowStockWarning(
      type: LowStockWarningType.saleExceedsStock,
      message: "Warning! This stock item's inventory level is below the sale quantity",
    );
  }

  bool get hasWarning => type != LowStockWarningType.none;
}
