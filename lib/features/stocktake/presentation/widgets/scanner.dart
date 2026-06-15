import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../../constants/colors.dart';
import '../../../../constants/theme_colors.dart';

class Scanner extends StatefulWidget {
  const Scanner({
    super.key,
    required this.constraints,
    required this.onScan,
    required this.controller,
    required this.isScan,
    required this.isManualCount,
    required this.horizontalPadding,
    required this.onStartScan,
    required this.onStopScan,
  });

  final BoxConstraints constraints;
  final Function(String) onScan;
  final MobileScannerController controller;
  final bool isScan;
  final bool isManualCount;
  final double horizontalPadding;
  final VoidCallback onStartScan;
  final VoidCallback onStopScan;

  @override
  State<Scanner> createState() => _ScannerState();
}

class _ScannerState extends State<Scanner> {
  final AudioPlayer _audioPlayer = AudioPlayer()
    ..setReleaseMode(ReleaseMode.stop);
  final _beepSource = AssetSource('audio/beep.mp3');

  String? _lastScannedBarcode;
  DateTime? _lastScanTime;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final media = MediaQuery.of(context);
    final bool isTabletLandscape = media.size.shortestSide >= 600 &&
        media.orientation == Orientation.landscape;
    return SizedBox(
      height:
          widget.constraints.maxHeight * (isTabletLandscape ? 0.26 : 0.2),
      child: widget.isScan
          ? ClipRRect(
              borderRadius:
                  BorderRadius.circular(isTabletLandscape ? 10 : 0),
              child: Container(
                color: isDark ? colors.surface : kThirdColor,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    MobileScanner(
                      controller: widget.controller,
                      onDetect: (capture) async {
                        final barcodes = capture.barcodes;
                        if (barcodes.isEmpty) return;

                        final String currentBarcode =
                            barcodes.first.rawValue ?? "";
                        if (currentBarcode.isEmpty) return;

                        // Debounce: prevent double processing of same frame
                        final now = DateTime.now();
                        if (_lastScanTime != null &&
                            now.difference(_lastScanTime!).inMilliseconds <
                                1000 &&
                            currentBarcode == _lastScannedBarcode) {
                          return;
                        }
                        _lastScanTime = now;

                        // Feedback
                        HapticFeedback.vibrate();
                        HapticFeedback.heavyImpact();
                        await _audioPlayer.stop();
                        _audioPlayer.play(_beepSource);

                        // Logic Branching
                        if (widget.isManualCount) {
                          // Manual Mode: Just fetch and let user type
                          widget.onScan(currentBarcode);
                        } else {
                          // Auto Count Mode
                          setState(() {
                            // Auto Count Logic
                            // Just trigger the scan callback.
                            // The logic for "Increment & Save" is now in the Parent's BlocListener
                            // We reset _lastScannedBarcode only if needed, but for "rapid fire"
                            // distinct scans, we rely on the debounce above.
                            _lastScannedBarcode = currentBarcode;
                            // setState(() {

                            // });
                            widget.onScan(currentBarcode);
                          });
                        }
                      },
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black54,
                        ),
                        child: IconButton(
                          onPressed: widget.onStopScan,
                          icon: const Icon(Icons.close),
                          color: Colors.white,
                          iconSize: 20,
                          padding: const EdgeInsets.all(6),
                          constraints: const BoxConstraints(),
                        ),
                      ),
                    ),
                    Center(
                      child: LayoutBuilder(
                        builder: (context, boxConstraints) {
                          return Container(
                            width: boxConstraints.maxWidth * 0.6,
                            height: 130,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: kPrimaryColor.withOpacity(0.7),
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            )
          : _scannerPlaceHolder(),
    );
  }

  Widget _scannerPlaceHolder() {
    final colors = context.appColors;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final media = MediaQuery.of(context);
    final bool isTablet = media.size.shortestSide >= 600;
    final bool isTabletLandscape =
        isTablet && media.orientation == Orientation.landscape;
    final double sidePadding =
        isTabletLandscape ? 0.0 : (isTablet ? widget.horizontalPadding : 15.0);

    return GestureDetector(
      onTap: widget.onStartScan,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: sidePadding),
        decoration: BoxDecoration(
          color: isDark ? colors.surface : Colors.grey.shade50,
          borderRadius: const BorderRadius.all(Radius.circular(10)),
          border: Border.all(
            color: isDark ? Colors.white38 : Colors.grey.shade400,
          ),
          //
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.qr_code_scanner,
                  size: 55,
                  color: kPrimaryColor.withOpacity(0.5),
                ),
                const SizedBox(height: 8),
                Text(
                  "Tap here to turn your scanner on.",
                  style: TextStyle(fontSize: 14, color: colors.onSurfaceMuted),
                ),
                const SizedBox(height: 4),
                Text(
                  "Your camera is turned off to preserve battery.",
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.onSurfaceMuted.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Original _scannerPlaceHolder (commented out for comparison)
  // Widget _scannerPlaceHolderOriginal() {
  //   final colors = context.appColors;
  //   final bool isDark = Theme.of(context).brightness == Brightness.dark;
  //   final bool isTablet = MediaQuery.of(context).size.shortestSide >= 600;
  //   final double sidePadding = isTablet ? widget.horizontalPadding : 15.0;
  //
  //   return Container(
  //     margin: EdgeInsets.symmetric(horizontal: sidePadding),
  //     decoration: BoxDecoration(
  //       gradient: isDark ? colors.heroGradient : kGColor,
  //       borderRadius: const BorderRadius.all(Radius.circular(10)),
  //       boxShadow: [
  //         BoxShadow(
  //           color: isDark ? colors.cardShadow : kThirdColor.withOpacity(0.05),
  //           blurRadius: 10,
  //           offset: const Offset(0, 4),
  //           spreadRadius: 0,
  //         ),
  //       ],
  //     ),
  //     child: Center(
  //       child: SingleChildScrollView(
  //         child: Column(
  //           mainAxisAlignment: MainAxisAlignment.center,
  //           children: [
  //             Icon(
  //               CupertinoIcons.barcode_viewfinder,
  //               size: 80,
  //               color: kSecondaryColor,
  //             ),
  //             const SizedBox(height: 10),
  //             Text(
  //               "Scan Barcode",
  //               style: TextStyle(
  //                 fontSize: 16,
  //                 color: kSecondaryColor,
  //                 fontWeight: FontWeight.w600,
  //               ),
  //             ),
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  // }
}
