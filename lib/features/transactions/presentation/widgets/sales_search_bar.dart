import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../constants/colors.dart';
import '../../../../constants/theme_colors.dart';

/// Search bar widget with scanner toggle for sales screen
class SalesSearchBar extends StatelessWidget {
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final bool showScanner;
  final bool isTorchOn;
  final VoidCallback onScannerToggle;
  final VoidCallback onTorchToggle;
  final ValueChanged<String> onSearch;

  const SalesSearchBar({
    super.key,
    required this.searchController,
    required this.searchFocusNode,
    required this.showScanner,
    required this.isTorchOn,
    required this.onScannerToggle,
    required this.onTorchToggle,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final bool isDark = colors.isDark;
    final bool isTablet = MediaQuery.of(context).size.shortestSide >= 600;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Container(
        height: isTablet ? 50 : 44,
        decoration: BoxDecoration(
          color: isDark ? colors.surface : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDark ? Colors.white24 : kPrimaryColor.withOpacity(0.5),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: searchController,
                focusNode: searchFocusNode,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: 'Scan barcode or type to search (F2)',
                  hintStyle: TextStyle(color: colors.onSurfaceMuted, fontSize: 13),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
                onSubmitted: (value) {
                  if (value.trim().isNotEmpty) {
                    onSearch(value.trim());
                    searchController.clear();
                  }
                },
              ),
            ),
            // Torch toggle (only visible when scanner is open)
            if (showScanner)
              GestureDetector(
                onTap: onTorchToggle,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(
                    isTorchOn ? Icons.flash_on : Icons.flash_off,
                    color: isTorchOn ? Colors.amber : colors.onSurfaceMuted,
                    size: 22,
                  ),
                ),
              ),
            // Scanner toggle
            GestureDetector(
              onTap: onScannerToggle,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Icon(
                  Icons.qr_code_scanner,
                  color: showScanner ? Colors.green : kPrimaryColor,
                  size: 22,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Scanner area widget for sales screen
class SalesScannerArea extends StatelessWidget {
  final MobileScannerController scannerController;
  final ValueChanged<String> onBarcodeScanned;

  const SalesScannerArea({
    super.key,
    required this.scannerController,
    required this.onBarcodeScanned,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final bool isDark = colors.isDark;
    final scannerHeight = MediaQuery.of(context).size.height * 0.18;

    return Container(
      height: scannerHeight,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? colors.surface : kThirdColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white24 : Colors.grey.shade400,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: kThirdColor.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: Stack(
          children: [
            MobileScanner(
              controller: scannerController,
              onDetect: (capture) {
                final barcodes = capture.barcodes;
                if (barcodes.isEmpty) return;

                final String currentBarcode = barcodes.first.rawValue ?? "";
                if (currentBarcode.isEmpty) return;

                onBarcodeScanned(currentBarcode);
              },
            ),
            // Scanner frame overlay
            Center(
              child: Container(
                width: MediaQuery.of(context).size.width * 0.55,
                height: scannerHeight * 0.7,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: kPrimaryColor.withOpacity(0.7),
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
