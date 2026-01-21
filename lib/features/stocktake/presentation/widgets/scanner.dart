import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:rmstock_scanner/features/stocktake/presentation/BLoC/stocktake_bloc.dart';

import '../../../../constants/colors.dart';
import '../../../../utils/log_utils.dart';
import '../BLoC/stocktake_events.dart';
import '../screens/scanner_screen.dart';

class Scanner extends StatefulWidget {
  const Scanner({super.key, required this.constraints});

  final BoxConstraints constraints;

  @override
  State<Scanner> createState() => _ScannerState();
}

class _ScannerState extends State<Scanner> {
  final AudioPlayer _audioPlayer = AudioPlayer()
    ..setReleaseMode(ReleaseMode.stop);

  final _beepSource = AssetSource('audio/beep.mp3');

  String? _lastScannedBarcode;

  @override
  Widget build(BuildContext context) {
    // Dynamic height based on screen size, but ensuring minimum visibility
    // 25% of available height is often better than 20% for readability
    return SizedBox(
      height: widget.constraints.maxHeight * 0.2,
      child: isScan
          ? Container(
              color: kThirdColor,
              child: Stack(
                children: [
                  MobileScanner(
                    controller: scannerController,
                    // returnImage: false, // Ensure this matches controller init in main screen
                    onDetect: (capture) async {
                      // ... (Your logic kept intact) ...
                      final String currentBarcode =
                          capture.barcodes.first.rawValue ?? "";

                      final barcodes = capture.barcodes;
                      if (barcodes.isEmpty) return;

                      logger.d(capture.barcodes);
                      HapticFeedback.vibrate();
                      HapticFeedback.heavyImpact();
                      await _audioPlayer.stop();
                      _audioPlayer.play(_beepSource);

                      if (isManualCount) {
                        final String code =
                            capture.barcodes.first.rawValue ?? "";

                        if (context.mounted) {
                          context.read<ScannerBloc>().add(
                            FetchStockDetails(barcode: code),
                          );
                        }

                        qtyFocusNode.requestFocus();
                        qtyController.selection = TextSelection(
                          baseOffset: 0,
                          extentOffset: qtyController.text.length,
                        );
                      } else {
                        setState(() {
                          if (_lastScannedBarcode == currentBarcode) {
                            int currentQty =
                                int.tryParse(qtyController.text) ?? 0;
                            qtyController.text = (currentQty + 1).toString();
                          } else {
                            if (context.mounted) {
                              context.read<ScannerBloc>().add(
                                FetchStockDetails(barcode: currentBarcode),
                              );
                            }
                            _lastScannedBarcode = currentBarcode;
                            qtyController.text = "1";
                          }
                        });

                        if (countingStock != null) {
                          if (context.mounted) {
                            context.read<StocktakeBloc>().add(
                              Stocktake(
                                qty: qtyController.text,
                                stock: countingStock!,
                              ),
                            );
                          }
                        }
                        logger.d(
                          "Stocktake saved with : ${qtyController.text}",
                        );
                      }
                    },
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
            )
          : _scannerPlaceHolder(),
    );
  }

  Widget _scannerPlaceHolder() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 25),
      decoration: BoxDecoration(
        gradient: kGColor,
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        boxShadow: [
          BoxShadow(
            color: kThirdColor.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Center(
        child: SingleChildScrollView(
          // Prevent overflow if screen extremely short
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                CupertinoIcons.barcode_viewfinder,
                weight: 1,
                size: 80, // Slightly reduced to fit better
                color: kSecondaryColor,
              ),
              const SizedBox(height: 10),
              const Text(
                "Scan Barcode",
                style: TextStyle(
                  fontSize: 16,
                  color: kSecondaryColor,
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
