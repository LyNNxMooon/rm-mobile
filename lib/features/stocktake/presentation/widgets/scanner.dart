import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/cupertino.dart';
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
  });

  final BoxConstraints constraints;
  final Function(String) onScan;
  final MobileScannerController controller;
  final bool isScan;
  final bool isManualCount;
  final double horizontalPadding;

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
    return SizedBox(
      height: widget.constraints.maxHeight * 0.2,
      child: widget.isScan
          ? Container(
              color: isDark ? colors.surface : kThirdColor,
              child: Stack(
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
                  Center(
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.6,
                      height: 130,
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
            )
          : _scannerPlaceHolder(),
    );
  }

  Widget _scannerPlaceHolder() {
    final colors = context.appColors;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isTablet = MediaQuery.of(context).size.shortestSide >= 600;
    final double sidePadding = isTablet ? widget.horizontalPadding : 15.0;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: sidePadding),
      decoration: BoxDecoration(
        gradient: isDark ? colors.heroGradient : kGColor,
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        boxShadow: [
          BoxShadow(
            color: isDark ? colors.cardShadow : kThirdColor.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                CupertinoIcons.barcode_viewfinder,
                size: 80,
                color: isDark ? colors.onHero : kSecondaryColor,
              ),
              const SizedBox(height: 10),
              Text(
                "Scan Barcode",
                style: TextStyle(
                  fontSize: 16,
                  color: isDark ? colors.onHero : kSecondaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
