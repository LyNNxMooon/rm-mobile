import 'package:flutter/material.dart';
import '../../../../constants/colors.dart';
import '../../../../constants/global_widgets.dart';
import '../../../../constants/txt_styles.dart';

class LoadingStocktakeDialog extends StatefulWidget {
  const LoadingStocktakeDialog({super.key});

  @override
  State<LoadingStocktakeDialog> createState() => _LoadingStocktakeDialogState();
}

class _LoadingStocktakeDialogState extends State<LoadingStocktakeDialog> {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 10,
      backgroundColor: kBgColor,

      child: Container(
        constraints: const BoxConstraints(maxHeight: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 26),
              decoration: BoxDecoration(
                gradient: kGColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.all_inbox, color: kSecondaryColor),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Text(
                      "Stocktaking",
                      style: getSmartTitle(fontSize: 18),
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      "Validating Stocktake Data...",
                      style: getSmartTitle(color: kThirdColor, fontSize: 16),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                        top: 25,
                        left: 60,
                        right: 60,
                        bottom: 5,
                      ),
                      child: ModernLoadingBar(),
                    ),
                    Text(
                      "This may take a few seconds.",
                      style: TextStyle(fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
