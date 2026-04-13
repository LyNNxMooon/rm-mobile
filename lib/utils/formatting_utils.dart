import 'package:decimal/decimal.dart';

/// Utility class for formatting numbers with cascading rounding
class FormattingUtils {
  /// Cascading rounding: rounds from the rightmost digit towards the target precision.
  /// Example: 4990.1148 → 4990.115 → 4990.12 (with decimals=2)
  /// 
  /// This differs from standard rounding which only looks at one digit past precision.
  static String cascadeRound(double value, int decimals) {
    if (value.isNaN || value.isInfinite) {
      return value.toStringAsFixed(decimals);
    }
    
    // Use Decimal for precise string conversion
    // Start with high precision string representation
    final str = value.toStringAsFixed(10);
    final d = Decimal.parse(str);
    
    // Round with cascade effect by using Decimal's precise rounding
    // Decimal.toStringAsFixed does proper mathematical rounding
    // We need to cascade from the end, so we round progressively
    
    // Get enough precision to work with
    String workingStr = d.toStringAsFixed(10);
    
    // Remove trailing zeros for easier processing
    while (workingStr.endsWith('0') && workingStr.contains('.')) {
      workingStr = workingStr.substring(0, workingStr.length - 1);
    }
    
    // Find decimal point position
    final dotIndex = workingStr.indexOf('.');
    if (dotIndex == -1) {
      // No decimal point, just return with zeros
      return '$workingStr.${'0' * decimals}';
    }
    
    final currentDecimals = workingStr.length - dotIndex - 1;
    if (currentDecimals <= decimals) {
      // Already at or below target precision
      return Decimal.parse(workingStr).toStringAsFixed(decimals);
    }
    
    // Cascade round from right to left
    Decimal result = Decimal.parse(workingStr);
    for (int i = currentDecimals; i > decimals; i--) {
      // Round to i-1 decimals
      final scale = Decimal.parse('1${'0' * (i - 1)}');
      result = ((result * scale).round() / scale).toDecimal();
    }
    
    return result.toStringAsFixed(decimals);
  }
  
  /// Format a double value as currency string with cascading rounding to 2 decimals
  static String formatCurrency(double value) {
    return '\$${cascadeRound(value, 2)}';
  }
  
  /// Format a double value with cascading rounding to specified decimals
  static String formatFixed(double value, int decimals) {
    return cascadeRound(value, decimals);
  }
}

/// Extension for convenient cascading rounding on double
extension CascadeRoundingExtension on double {
  /// Cascade round to specified decimal places and return as String
  String toCascadeFixed(int decimals) => FormattingUtils.cascadeRound(this, decimals);
  
  /// Cascade round to 2 decimal places and return as String
  String toCascadeFixed2() => FormattingUtils.cascadeRound(this, 2);
  
  /// Cascade round to 4 decimal places and return as String
  String toCascadeFixed4() => FormattingUtils.cascadeRound(this, 4);
}
