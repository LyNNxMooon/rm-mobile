import 'package:flutter/material.dart';
import '../../../../constants/colors.dart';
import '../../../../utils/dialog_size_utils.dart';

class StocktakeQuestionDialog extends StatelessWidget {
  const StocktakeQuestionDialog({
    super.key,
    required this.message,
    required this.onYesPressed,
    this.title = "Are you sure?",
    this.onNoPressed,
  });

  final String title;
  final String message;
  final VoidCallback onYesPressed;
  final VoidCallback? onNoPressed;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: dialogInsetPadding(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 10,
      backgroundColor: kBgColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Question Icon Bubble
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: kPrimaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.help_outline_rounded,
                  color: kPrimaryColor,
                  size: 32,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: kThirdColor,
              ),
            ),
            const SizedBox(height: 12),

            // Message Body
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: kThirdColor.withOpacity(0.8),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                // NO Button
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      if (onNoPressed != null) {
                        onNoPressed!();
                      } else {
                        Navigator.of(context).pop(); // Default Close
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: kPrimaryColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      "No",
                      style: TextStyle(
                        color: kPrimaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // YES Button
                Expanded(
                  child: ElevatedButton(
                    onPressed: onYesPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      "Yes",
                      style: TextStyle(
                        color: kSecondaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
