import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../constants/colors.dart';
import '../../../../constants/theme_colors.dart';
import '../../../../utils/responsive_utils.dart';

/// Search bar widget with scanner toggle for sales screen
class SalesSearchBar extends StatelessWidget {
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final bool showScanner;
  final bool isTorchOn;
  final VoidCallback onScannerToggle;
  final VoidCallback onTorchToggle;
  final ValueChanged<String> onSearch;
  final VoidCallback? onGoToStockLookup;

  const SalesSearchBar({
    super.key,
    required this.searchController,
    required this.searchFocusNode,
    required this.showScanner,
    required this.isTorchOn,
    required this.onScannerToggle,
    required this.onTorchToggle,
    required this.onSearch,
    this.onGoToStockLookup,
  });

  Widget _buildIconButton({
    required bool isTablet,
    required bool isDark,
    required AppThemeColors colors,
    required IconData icon,
    required VoidCallback onTap,
    required Color iconColor,
    bool isActive = false,
  }) {
    final double size = isTablet ? 38 : 34;
    final Color borderColor = isDark
        ? Colors.white30
        : (isActive ? kPrimaryColor.withOpacity(0.8) : kPrimaryColor.withOpacity(0.55));
    final Color background = isActive
        ? kPrimaryColor.withOpacity(isDark ? 0.25 : 0.18)
        : (isDark ? colors.surfaceAlt : kPrimaryColor.withOpacity(0.08));

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: size + 6,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor),
        ),
        child: Icon(icon, color: iconColor, size: isTablet ? 22 : 20),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final bool isDark = colors.isDark;
    final bool isTablet = context.isTablet;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Container(
        height: isTablet ? 46 : 40,
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
                  hintText: 'Scan barcode or type to search',
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
            if (showScanner) ...[
              Padding(
                padding: EdgeInsets.only(left: isTablet ? 10 : 8, right: 8),
                child: _buildIconButton(
                  isTablet: isTablet,
                  isDark: isDark,
                  colors: colors,
                  icon: isTorchOn ? Icons.flash_on : Icons.flash_off,
                  onTap: onTorchToggle,
                  iconColor: isTorchOn ? Colors.amber : colors.onSurfaceMuted,
                  isActive: isTorchOn,
                ),
              ),
            ],
            // Scanner toggle
            Padding(
              padding: EdgeInsets.only(left: isTablet ? 10 : 8, right: 8),
              child: _buildIconButton(
                isTablet: isTablet,
                isDark: isDark,
                colors: colors,
                icon: Icons.qr_code_scanner,
                onTap: onScannerToggle,
                iconColor: showScanner ? Colors.green : kPrimaryColor,
                isActive: showScanner,
              ),
            ),
            // Go to Stock Lookup button
            if (onGoToStockLookup != null)
              Padding(
                padding: EdgeInsets.only(left: isTablet ? 10 : 8, right: 8),
                child: _buildIconButton(
                  isTablet: isTablet,
                  isDark: isDark,
                  colors: colors,
                  icon: Icons.double_arrow_rounded,
                  onTap: onGoToStockLookup!,
                  iconColor: kPrimaryColor,
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

    return LayoutBuilder(
      builder: (context, constraints) {
        // Use parent constraint if available, otherwise fall back to percentage
        final scannerHeight = constraints.maxHeight.isFinite 
            ? constraints.maxHeight 
            : MediaQuery.of(context).size.height * 0.18;
        
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
      },
    );
  }
}
