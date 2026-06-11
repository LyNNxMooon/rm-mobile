import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../constants/colors.dart';
import '../../../../constants/theme_colors.dart';
import '../../../../utils/responsive_utils.dart';

/// Search bar widget with scanner toggle for sales screen
class SalesSearchBar extends StatefulWidget {
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final bool showScanner;
  final bool isTorchOn;
  final VoidCallback? onScannerToggle;
  final VoidCallback? onTorchToggle;
  final ValueChanged<String> onSearch;
  final VoidCallback? onGoToStockLookup;

  const SalesSearchBar({
    super.key,
    required this.searchController,
    required this.searchFocusNode,
    required this.showScanner,
    required this.isTorchOn,
    this.onScannerToggle,
    this.onTorchToggle,
    required this.onSearch,
    this.onGoToStockLookup,
  });

  @override
  State<SalesSearchBar> createState() => _SalesSearchBarState();
}

class _SalesSearchBarState extends State<SalesSearchBar> {
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    widget.searchFocusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    widget.searchFocusNode.removeListener(_onFocusChange);
    super.dispose();
  }

  void _onFocusChange() {
    if (mounted) {
      setState(() => _isFocused = widget.searchFocusNode.hasFocus);
    }
  }

  Widget _buildIconButton({
    required bool isTablet,
    required bool isDark,
    required AppThemeColors colors,
    required IconData icon,
    required VoidCallback onTap,
    required Color iconColor,
    bool isActive = false,
  }) {
    final double size = isTablet ? 44 : 40;
    final Color background = isActive
        ? kPrimaryColor.withOpacity(isDark ? 0.25 : 0.18)
        : (isDark ? const Color(0xFF212121) : kPrimaryColor.withOpacity(0.08));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: background,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: isTablet ? 22 : 20),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final bool isDark = colors.isDark;
    final bool useDesktopNav = context.useDesktopNav;
    final bool isTablet = context.isTablet;
    final double containerHeight = useDesktopNav ? 36 : (isTablet ? 46 : 40);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: containerHeight,
              decoration: BoxDecoration(
                color: isDark ? Colors.black : Colors.white,
                borderRadius: BorderRadius.circular(containerHeight / 2),
                border: Border.all(
                  color: _isFocused
                      ? kPrimaryColor
                      : (isDark ? Colors.white24 : kPrimaryColor.withOpacity(0.5)),
                  width: _isFocused ? 2 : 1,
                ),
              ),
              child: Center(
                child: TextField(
                  controller: widget.searchController,
                  focusNode: widget.searchFocusNode,
                  // Disable autocorrect and predictive text
                  autocorrect: false,
                  enableSuggestions: false,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: useDesktopNav ? 13 : 14,
                  ),
                  textAlignVertical: TextAlignVertical.center,
                  decoration: InputDecoration(
                    hintText: 'Scan barcode or type to search',
                    hintStyle: TextStyle(
                      color: colors.onSurfaceMuted,
                      fontSize: useDesktopNav ? 12 : 13,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: useDesktopNav ? 8 : 10,
                    ),
                  ),
                  onSubmitted: (value) {
                    if (value.trim().isNotEmpty) {
                      widget.onSearch(value.trim());
                      widget.searchController.clear();
                    }
                  },
                ),
              ),
            ),
          ),
          // Torch toggle (only visible when scanner is open)
          if (widget.showScanner && widget.onTorchToggle != null) ...[
            SizedBox(width: isTablet ? 10 : 8),
            _buildIconButton(
              isTablet: isTablet,
              isDark: isDark,
              colors: colors,
              icon: widget.isTorchOn ? Icons.flash_on : Icons.flash_off,
              onTap: widget.onTorchToggle!,
              iconColor: widget.isTorchOn ? Colors.amber : colors.onSurfaceMuted,
              isActive: widget.isTorchOn,
            ),
          ],
          // Scanner toggle (hidden on desktop where scanner is not available)
          if (widget.onScannerToggle != null) ...[
            SizedBox(width: isTablet ? 10 : 8),
            _buildIconButton(
              isTablet: isTablet,
              isDark: isDark,
              colors: colors,
              icon: Icons.qr_code_scanner,
              onTap: widget.onScannerToggle!,
              iconColor: widget.showScanner ? Colors.green : kPrimaryColor,
              isActive: widget.showScanner,
            ),
          ],
          // Go to Stock Lookup button
          if (widget.onGoToStockLookup != null) ...[
            SizedBox(width: isTablet ? 10 : 8),
            _buildIconButton(
              isTablet: isTablet,
              isDark: isDark,
              colors: colors,
              icon: Icons.double_arrow_rounded,
              onTap: widget.onGoToStockLookup!,
              iconColor: kPrimaryColor,
            ),
          ],
        ],
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
