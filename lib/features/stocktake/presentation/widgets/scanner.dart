import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../constants/colors.dart';
import '../../../../utils/log_utils.dart';
import '../screens/scanner_screen.dart';

class Scanner extends StatefulWidget {
  const Scanner({super.key, required this.constraints});

  final BoxConstraints constraints;

  @override
  State<Scanner> createState() => _ScannerState();
}

class _ScannerState extends State<Scanner> {
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.constraints.maxHeight * 0.2,
      child: isScan
          ? Container(
              color: kThirdColor,
              child: Stack(
                children: [
                  MobileScanner(
                    controller: scannerController,
                    tapToFocus: true,
                    onDetect: (capture) async {
                      final barcodes = capture.barcodes;
                      //barcodes.last.rawValue.toString()

                      logger.d(capture);
                      await HapticFeedback.vibrate();

                      // if (await Vibration.hasVibrator()) {
                      //   Vibration.vibrate();
                      // }

                      await HapticFeedback.heavyImpact();

                      await _audioPlayer.play(AssetSource('audio/beep.mp3'));
                      if (!isManualCount) {
                        setState(() {
                          int currentQty =
                              int.tryParse(qtyController.text) ?? 0;
                          qtyController.text = (currentQty + 1).toString();
                        });
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                CupertinoIcons.barcode_viewfinder,
                weight: 1,
                fontWeight: FontWeight.w100,
                size: 100,
                color: kSecondaryColor,
              ),
              Text(
                "Scan Barcode",
                style: TextStyle(fontSize: 16, color: kSecondaryColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
