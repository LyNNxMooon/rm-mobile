import 'package:flutter/material.dart';
import 'package:rmstock_scanner/utils/navigation_extension.dart';

import '../../../../constants/colors.dart';
import '../../../../constants/txt_styles.dart';
import '../../../../utils/enums.dart';
import '../../../../utils/global_var_utils.dart';
import '../screens/scanner_screen.dart';

class StocktakeAppbarSession extends StatefulWidget {
  const StocktakeAppbarSession({super.key});

  @override
  State<StocktakeAppbarSession> createState() => _StocktakeAppbarSessionState();
}

class _StocktakeAppbarSessionState extends State<StocktakeAppbarSession> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () => context.navigateBack(),
                icon: const Icon(
                  Icons.arrow_back_ios,
                  color: kThirdColor,
                  size: 15,
                ),
              ),
              Text(
                (AppGlobals.instance.shopfront ?? "RM-Shopfront")
                            .split('\\')
                            .last
                            .length >
                        22
                    ? "${(AppGlobals.instance.shopfront ?? "RM-Shopfront").split('\\').last.substring(0, 22)}..."
                    : (AppGlobals.instance.shopfront ?? "RM-Shopfront")
                          .split('\\')
                          .last,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              IconButton(
                icon: Icon(
                  isTorchOn ? Icons.light_mode : Icons.light_mode_outlined,
                  color: kThirdColor,
                ),
                onPressed: () {
                  setState(() {
                    scannerController.toggleTorch();
                    isTorchOn = !isTorchOn;
                  });
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class ScanModeSelector extends StatefulWidget {
  final ValueChanged<ScanMode> onModeChanged;

  const ScanModeSelector({super.key, required this.onModeChanged});

  @override
  State<ScanModeSelector> createState() => _ScanModeSelectorState();
}

class _ScanModeSelectorState extends State<ScanModeSelector> {
  ScanMode _selectedMode = ScanMode.manualCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildRadioOption(
          text: "Scan and Manual Count",
          value: ScanMode.manualCount,
        ),
        const SizedBox(width: 18),
        _buildRadioOption(
          text: "Scan and Auto Count",
          value: ScanMode.autoCount,
        ),
      ],
    );
  }

  Widget _buildRadioOption({required String text, required ScanMode value}) {
    final bool isSelected = _selectedMode == value;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedMode = value;
        });
        widget.onModeChanged(value);
      },
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 16,
              height: 16,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,

                border: Border.all(
                  color: isSelected ? kPrimaryColor : kGreyColor,
                  width: 2,
                ),
                color: Colors.transparent,
              ),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? kPrimaryColor : Colors.transparent,
                ),
              ),
            ),
            const SizedBox(width: 10),

            Text(
              text,
              style: getSmartTitle(
                fontSize: 11,
                color: isSelected ? kThirdColor : kGreyColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
