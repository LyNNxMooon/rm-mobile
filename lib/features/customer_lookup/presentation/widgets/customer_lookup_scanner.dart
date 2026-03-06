import 'package:flutter/cupertino.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../constants/colors.dart';

class CustomerLookupScanner extends StatefulWidget {
  const CustomerLookupScanner({super.key, required this.function});

  final void Function(BarcodeCapture)? function;

  @override
  State<CustomerLookupScanner> createState() => _CustomerLookupScannerState();
}

class _CustomerLookupScannerState extends State<CustomerLookupScanner> {
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    detectionTimeoutMs: 1000,
    returnImage: false,
  );

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final bool isTablet = media.size.shortestSide >= 600;
    final double scannerHeight = isTablet
        ? (media.size.height * 0.24).clamp(170.0, 280.0)
        : (media.size.height * 0.2).clamp(130.0, 210.0);
    final double guideHeight = isTablet
        ? (scannerHeight * 0.62).clamp(120.0, 170.0)
        : (scannerHeight * 0.58).clamp(110.0, 150.0);
    final double guideWidth = isTablet
        ? (media.size.width * 0.52).clamp(260.0, 520.0)
        : (media.size.width * 0.6).clamp(180.0, 340.0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SizedBox(
        height: scannerHeight,
        child: Container(
          color: kThirdColor,
          child: Stack(
            children: [
              MobileScanner(
                controller: _scannerController,
                tapToFocus: true,
                onDetect: widget.function,
              ),
              Center(
                child: Container(
                  width: guideWidth,
                  height: guideHeight,
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
      ),
    );
  }
}
