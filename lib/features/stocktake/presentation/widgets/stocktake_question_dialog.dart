import 'package:flutter/material.dart';
import '../../../../constants/colors.dart';
import '../../../../constants/txt_styles.dart';

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
                  child: SizedBox(
                    height: 35,
                    child: OutlinedButton(
                      onPressed: () {
                        if (onNoPressed != null) {
                          onNoPressed!();
                        } else {
                          Navigator.of(context).pop(); // Default Close
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: kPrimaryColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        "No",
                        style: getSmartTitle(color: kPrimaryColor, fontSize: 16),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // YES Button
                Expanded(
                  child: SizedBox(
                    height: 35,
                    child: ElevatedButton(
                      onPressed: onYesPressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryColor,
                        foregroundColor: kSecondaryColor,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        "Yes",
                        style: getSmartTitle(color: kSecondaryColor, fontSize: 16),
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