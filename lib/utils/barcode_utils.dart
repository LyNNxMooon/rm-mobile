/// Utilities for normalising barcodes captured from the camera scanner.
class BarcodeUtils {
  BarcodeUtils._();

  /// Returns the "numeric only" form of [barcode] used for barcode searches.
  ///
  /// If [barcode] is digits-only, all leading zeros are removed
  /// (e.g. "001234" -> "1234") and returned as a [String] so it can be
  /// compared against the TEXT Barcode column. If it contains any non-digit
  /// character (alphanumeric), the trimmed value is returned unchanged so the
  /// caller can search it as-is.
  static String numericOnly(String barcode) {
    final trimmed = barcode.trim();
    // Only digit-only barcodes get their leading zeros removed.
    if (trimmed.isEmpty || !RegExp(r'^\d+$').hasMatch(trimmed)) {
      return trimmed;
    }
    final stripped = trimmed.replaceFirst(RegExp(r'^0+'), '');
    return stripped.isEmpty ? '0' : stripped;
  }
}
