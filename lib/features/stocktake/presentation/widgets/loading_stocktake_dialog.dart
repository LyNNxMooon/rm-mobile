import 'package:flutter/material.dart';
import '../../../../constants/global_widgets.dart';
import '../../../../constants/theme_colors.dart';
import '../../../../constants/txt_styles.dart';
import '../../../../utils/dialog_size_utils.dart';

class LoadingStocktakeDialog extends StatefulWidget {
  const LoadingStocktakeDialog({super.key});

  @override
  State<LoadingStocktakeDialog> createState() => _LoadingStocktakeDialogState();
}

class _LoadingStocktakeDialogState extends State<LoadingStocktakeDialog> {
  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Dialog(
      insetPadding: dialogInsetPadding(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 10,
      backgroundColor: colors.surface,

      child: Container(
        constraints: const BoxConstraints(maxHeight: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 26),
              decoration: BoxDecoration(
                gradient: colors.heroGradient,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.all_inbox, color: colors.onHero),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Text(
                      "Stocktaking",
                      style: getSmartTitle(
                        color: colors.onHero,
                        fontSize: 18,
                      ),
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
                      style: getSmartTitle(
                        color: colors.onSurface,
                        fontSize: 16,
                      ),
                    ),
                    Container(
                      width: 200,
                      padding: const EdgeInsets.only(
                        top: 25,
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
