
import 'package:flutter/cupertino.dart';

import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../constants/colors.dart';


class StockLookupScanner extends StatefulWidget {
  const StockLookupScanner({super.key, required this.function});

  final void Function(BarcodeCapture)? function;

  @override
  State<StockLookupScanner> createState() => _StockLookupScannerState();
}

class _StockLookupScannerState extends State<StockLookupScanner> {
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    detectionTimeoutMs: 1000,
    returnImage: false,
  );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.2,
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
                  width: 250,
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
        ),
      ),
    );
  }
}
